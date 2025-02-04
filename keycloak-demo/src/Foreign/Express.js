import express from 'express';
import session from 'express-session';
import crypto from 'crypto';
import cors from 'cors';
import ejs from 'ejs';
import passport from 'passport';
import * as dotenv from 'dotenv-safe';
import path from 'path';
import { dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables
dotenv.config({
  path: path.join(__dirname, '.env'),
  example: path.join(__dirname, '.env.example'),
  allowEmptyValues: true,
});

const {
  KEYCLOAK_REALM,
  KEYCLOAK_AUTH_SERVER_URL,
  KEYCLOAK_CLIENT_ID,
  KEYCLOAK_CALLBACK_URL,
  COOKIE_ORIGIN,
  SESSION_DOMAIN,
  SESSION_SECRET,
  NODE_ENV
} = process.env;

function validateEnv() {
  const requiredVars = [
    { name: "KEYCLOAK_REALM", value: KEYCLOAK_REALM },
    { name: "KEYCLOAK_AUTH_SERVER_URL", value: KEYCLOAK_AUTH_SERVER_URL },
    { name: "KEYCLOAK_CLIENT_ID", value: KEYCLOAK_CLIENT_ID },
    { name: "KEYCLOAK_CALLBACK_URL", value: KEYCLOAK_CALLBACK_URL },
    { name: "COOKIE_ORIGIN", value: COOKIE_ORIGIN },
    { name: "SESSION_DOMAIN", value: SESSION_DOMAIN },
    { name: "SESSION_SECRET", value: SESSION_SECRET },
  ];

  for (const variable of requiredVars) {
    if (!variable.value) {
      console.error(`Error: ${variable.name} is not defined in the environment variables.`);
      process.exit(1);
    }
  }
}

const isProduction = NODE_ENV === 'production';

function generateCodeVerifier(length = 128) {
  const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  return Array.from({ length }, () => possible.charAt(Math.floor(Math.random() * possible.length))).join('');
}

function generateCodeChallenge(codeVerifier) {
  return crypto.createHash('sha256').update(codeVerifier).digest('base64url');
}

export const createServerImpl = () => {

  validateEnv();

  const app = express();

  // CORS configuration
  app.use(
    cors({
      origin: COOKIE_ORIGIN,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      credentials: true,
    })
  );

  // View engine setup
  app.set('views', path.join(process.cwd(), 'static', 'views'));
  app.use(express.static(path.join(process.cwd(), 'static', 'public')));
  app.use('/css', express.static(path.join(process.cwd(), 'static', 'css')));
  app.engine('html', ejs.renderFile);
  app.set('view engine', 'html');

  app.use(express.urlencoded({ extended: true }));
  app.use(express.json());
  
  // Session / Cookies
  app.use(session({
    name: 'keycloak-session',
    secret: SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    rolling: true, // Force the session identifier cookie to be set on every response
    cookie: {
      domain: SESSION_DOMAIN,
      httpOnly: true,
      secure: isProduction,
      sameSite: isProduction ? 'none' : 'lax',
      path: '/',
      maxAge: 15 * 60 * 1000, // 15 minutes
    }
  }));
  
  // Setup Passport.js
  passport.serializeUser((user, done) => {
    done(null, JSON.stringify(user));
  });

  passport.deserializeUser((serialized, done) => {
    try {
      const user = JSON.parse(serialized);
      done(null, user);
    } catch (err) {
      done(err);
    }
  });

  app.use(passport.initialize());
  app.use(passport.session());

  // A very simple logging middleware
  app.use((req, res, next) => {
    // console.log('=== Request Debug ===');
    console.info('URL:', req.url);
    // console.log('Method:', req.method);
    // console.log('Headers:', req.headers);
    // console.log('Session ID:', req.sessionID);
    next();
  });

  /*********
  * ROUTES
  *********/
  app.get('/', (req, res) => {
    res.send('<h1>Welcome to Keycloak Demo</h1><p>Visit <a href="/auth/keycloak-init">Login</a></p>');
  });

  app.get('/login', (req, res) => {
    res.status(401).send('Authentication Failed. Please try again.');
  });

  app.get('/logout', (req, res, next) => {
    if (!req.isAuthenticated || !req.isAuthenticated()) {
      req.session.destroy((err) => {
        if (err) console.error('Session destruction error:', err);
        return res.redirect('/auth/keycloak-init');
      });
      return;
    }
  
    // Since our PureScript verify callback converts the profile to native form,
    // we expect the id token to be stored as _id_token.
    const user = req.user || {};
    const idToken = user._id_token;
    if (!idToken) {
      console.warn('No id_token in session; ending local session only.');
      req.session.destroy((err) => {
        if (err) console.error('Session destruction error:', err);
        return res.redirect('/auth/keycloak-init');
      });
      return;
    }
  
    // Read configuration from environment (or fallback defaults)
    const keycloakUrl = process.env.KEYCLOAK_URL || 'http://keycloak:8080';
    const realm = process.env.KEYCLOAK_REALM || 'TestRealm';
    const postLogoutRedirectUri = process.env.POST_LOGOUT_REDIRECT_URI || 'http://localhost:3002/auth/keycloak-init';
  
    // Build the Keycloak logout URL using the native id token.
    const logoutUrl =
      `${keycloakUrl}/realms/${realm}/protocol/openid-connect/logout` +
      `?id_token_hint=${encodeURIComponent(idToken)}` +
      `&post_logout_redirect_uri=${encodeURIComponent(postLogoutRedirectUri)}`;
  
    // Destroy the local session, then send an HTML snippet that redirects.
    req.session.destroy((err) => {
      if (err) console.error('Session destruction error:', err);
      res.send(`
        <html>
          <body>
            <script>
              window.location.href = '${logoutUrl}';
            </script>
          </body>
        </html>
      `);
    });
  });  
  

  app.get('/auth/keycloak-init', (req, res) => {

    let code_verifier = generateCodeVerifier();
    let code_challenge = generateCodeChallenge(code_verifier);

    req.session.code_verifier = code_verifier;
    req.session.code_challenge = code_challenge;

    req.session.save((err) => {
      if (err) {
        console.error(`Could not save session!: ${err}`);
        return res.status(500).send('Session save error');
      }
      res.redirect('/auth/keycloak')
    });
  });

  app.get('/auth/keycloak', (req, res, next) => {

    if (!req.session.code_challenge) {
      console.error('Missing code_challenge in session:');
      return res.status(400).send('Invalid authentication request.');
    }

    passport.authenticate('keycloak', {
      scope: ['openid', 'profile', 'email'],
      code_challenge: req.session.code_challenge,
      code_challenge_method: 'S256'
    })(req, res, next);
  });

  app.get('/auth/keycloak/callback', (req, res, next) => {
    if (!req.query.state || !req.query.code || !req.headers.cookie) {
      return res.status(400).send('Invalid authentication request');
    }
  
    passport.authenticate('keycloak', (err, user, info) => {
      if (err) {
        console.error('Authentication Error:', err);
        return res.redirect('/login');
      }
  
      if (!user) {
        console.error('No user:', info);
        return res.redirect('/login');
      }
  
      req.logIn(user, (loginErr) => {
        if (loginErr) {
          console.error('Login Error:', loginErr);
          return res.redirect('/login');
        }
        
        req.session.authenticated = true;
        req.session.save((saveErr) => {
          if (saveErr) {
            console.error('Session Save Error:', saveErr);
            return res.redirect('/login');
          }
          return res.redirect('/profile');
        });
      });
    })(req, res, next);
  });
  
  app.get('/profile', (req, res) => {
    if (!req.isAuthenticated() || !req.session.authenticated) {
      return res.redirect('/login');
    }
    
    res.render('profile.html', { 
      userProfile: req.session.profile || req.user 
    });
  });

  return app;
};

/************
 * EXPORTS
************/

export const fromForeign = req => req;

export const listenImpl = app => port => () => {
  app.listen(port);
};

export const getImpl = app => path => handler => () => {
  app.get(path, (req, res) => {
    handler(req)(res)();
  });
};

export const setSessionImpl = req => key => value => () => {
  req.session[key] = value;
  return req.session.save();
};

export const getSessionImpl = req => key => () => {
  return req.session[key] || null;
};

export const destroySessionImpl = req => () => {
  return new Promise((resolve) => {
    req.session.destroy(() => resolve());
  });
};

export const isAuthenticatedImpl = req => () => {
  return req.isAuthenticated ? req.isAuthenticated() : false;
};

export const redirectImpl = res => path => () => {
  res.redirect(path);
};

export const sendImpl = res => data => () => {
  res.send(data);
};

export const statusImpl = res => code => () => {
  return res.status(code);
};

export const loginImpl = (req) => (user) => () => {
  return new Promise((resolve, reject) => {
    req.logIn(user, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });
};
