const callDone = (done) => {
  return function(error) {
    return function(user) {
      return function() {
        // Call the raw JS done callback with error and user.
        return done(error, user);
      };
    };
  };
};

export {
  callDone
}
