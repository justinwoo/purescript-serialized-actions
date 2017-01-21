exports.dangerousLog = function (a) {
  return function () {
    console.log(a);
  };
};
