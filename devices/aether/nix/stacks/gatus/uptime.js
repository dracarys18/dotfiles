(function () {
  var bannerId = 'gatus-uptime-banner';
  var window = '30d';
  var state = { label: '30-day uptime', value: '…', count: '', health: 'unknown' };

  function span(className) {
    var element = document.createElement('span');
    element.className = className;
    return element;
  }

  function setText(element, text) {
    if (element && element.textContent !== text) {
      element.textContent = text;
    }
  }

  function series() {
    return fetch('/api/v1/endpoints/statuses', { cache: 'no-store' })
      .then(function (response) {
        return response.json();
      })
      .then(function (statuses) {
        return Promise.all(
          statuses.map(function (status) {
            return fetch('/api/v1/endpoints/' + encodeURIComponent(status.key) + '/uptimes/' + window, { cache: 'no-store' })
              .then(function (response) {
                return response.json();
              })
              .catch(function () {
                return null;
              });
          })
        );
      });
  }

  function mount() {
    var heading = document.querySelector('.dashboard-container h1');
    if (!heading) {
      return;
    }
    var banner = document.getElementById(bannerId);
    if (!banner) {
      banner = document.createElement('div');
      banner.id = bannerId;
      banner.appendChild(span('label'));
      banner.appendChild(span('value'));
      banner.appendChild(span('count'));
      heading.parentElement.appendChild(banner);
    }
    setText(banner.querySelector('.label'), state.label);
    setText(banner.querySelector('.value'), state.value);
    setText(banner.querySelector('.count'), state.count);
    if (banner.getAttribute('data-health') !== state.health) {
      banner.setAttribute('data-health', state.health);
    }
  }

  function linkHostnames() {
    var hosts = document.querySelectorAll('.dashboard-container .endpoint .text-muted-foreground span');
    for (var i = 0; i < hosts.length; i++) {
      var element = hosts[i];
      var host = element.textContent;
      if (element.querySelector('a') || !/^[a-z0-9-]+(\.[a-z0-9-]+)*\.karthihegde\.dev$/.test(host)) {
        continue;
      }
      var link = document.createElement('a');
      link.className = 'gatus-hostname-link';
      link.href = 'https://' + host;
      link.target = '_blank';
      link.rel = 'noopener noreferrer';
      link.textContent = host;
      element.textContent = '';
      element.appendChild(link);
    }
  }

  function refresh() {
    series()
      .then(function (uptimes) {
        var values = uptimes.filter(function (value) {
          return typeof value === 'number' && isFinite(value) && value >= 0 && value <= 1;
        });
        if (values.length === 0) {
          throw new Error('no uptime data');
        }
        var measured = values.reduce(function (a, b) {
          return a + b;
        }, 0) / values.length;
        var percent = measured * 100;
        state = {
          label: '30-day uptime',
          value: percent.toFixed(3) + '%',
          count: values.length + (values.length === 1 ? ' service' : ' services'),
          health: percent >= 99.9 ? 'good' : percent >= 99 ? 'warn' : 'bad'
        };
      })
      .catch(function () {
        state = { label: '30-day uptime', value: 'unavailable', count: '', health: 'unknown' };
      })
      .then(mount);
  }

  refresh();
  linkHostnames();
  setInterval(refresh, 60000);
  setInterval(mount, 2000);
  setInterval(linkHostnames, 2000);
})();
