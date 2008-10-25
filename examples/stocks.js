var re = /href="\/q\?s=(\w+)([^<]|(<[^a]))*?color:#([a-fA-F0-9]{6});/g;

download('http://finance.yahoo.com/q?s=SNE+NTDOY+GOOG+MSFT+AAPL', {
  onComplete: function (page) {
    var m;
    while (m = re.exec(page)) {
      log(m[1] + '=' + m[4]);
      keys[m[1][0]] = m[4];
    }
  },
  onError: log
});
