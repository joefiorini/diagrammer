var result = {
  id: '',
  isStart: false,
  isDrop: false,
  isEnd: false,
  isMulti: false,
  startX: 0,
  startY: 0,
  endX: 0,
  endY: 0
};

var board = Elm.Main.fullscreen();
// var board = Elm.Main.fullscreen({
//   dragstart: result,
//   dragend: result,
//   drop: result,
//   globalKeyDown: 0,
//   loadedState: ""
// });

function StyleWithColor() {
  return {
    adapt: function(obj) {
      obj.style = { color: 'white' };
      return obj;
    }
  };
}

document.onkeydown = function(e) {
  if (e.keyCode == 9) {
    e.preventDefault();
  }
};

function adapt(state) {
  var adapters = [StyleWithColor()];
  return adapters.reduce(function(updated, adapter) {
    return adapter.adapt(updated);
  }, state);
}

function runApp(e) {
  if (window.localStorage.getItem('sawIntro') == null) {
    window.localStorage.setItem('sawIntro', true);
    window.location.href = 'http://tinyurl.com/luq57yc';
  }

  var currentUrl = window.location.href;
  var matches = currentUrl.match(/\/boards\/(.*)$/);

  if (matches && matches.length && matches.length > 0) {
    var serializedState = matches[1];
    var decodedState = decodeURIComponent(serializedState);
    var deserializedState = JSON.parse(atob(decodedState));
    var adaptedState = adapt(deserializedState);
    console.log(adaptedState);
    board.ports.loadedState.send(adaptedState);
    window.history.pushState({}, '', '/');
  }
}

var forms = document.querySelectorAll('form');

window.onsubmit = function(e) {
  e.preventDefault();
};

// preventDefault(forms, "submit");

// board.ports.focus.subscribe(function (selector) {
//   setTimeout(function () {
//     var nodes = document.querySelectorAll(selector);
//     if (nodes.length === 1 && document.activeElement !== nodes[0]) {
//       nodes[0].focus()
//       nodes[0].setSelectionRange(0, nodes[0].value.length)
//     }
//   }, 50);
// });

function urlForState(state) {
  var encoded = encodeURIComponent(state);
  return (
    window.location.protocol +
    '//' +
    window.location.host +
    '/boards/' +
    encoded
  );
}

board.ports.serializeState.subscribe(function(state) {
  var encoded = btoa(JSON.stringify(state));
  var input = document.querySelector('.share__url');
  var url = urlForState(encoded);

  input.value = url;
  input.select();
  return state;
});

// board.ports.transitionToRoute.subscribe(function(url) {
//   window.history.pushState({}, '', url);
// });

var links = document.querySelectorAll("a[href='#']");
preventDefault(links, 'click');

function preventDefault(nodes, event) {
  Array.prototype.slice.apply(nodes).forEach(function(node) {
    node.addEventListener(event, function(e) {
      e.preventDefault();
    });
  });
}

function sendPort(port, result) {
  console.log('sending ', port, result);

  result.isStart = result.isEnd = result.isDrop = false;

  switch (port) {
    case 'dragstart':
      result.isStart = true;
      break;
    case 'dragend':
      result.isEnd = true;
      break;
    case 'drop':
      result.isDrop = true;
      break;
  }

  board.ports[port].send(result);
}

setTimeout(function() {
  var navBar = document.querySelector('nav.nav-bar');
  navBar.classList.add('nav-bar--compressed');
}, 5000);

setTimeout(function() {
  var container = document.querySelector('main');
  container.addEventListener(
    'dragstart',
    function(e) {
      result.id = e.target.id;
      result.startX = e.clientX;
      result.startY = e.clientY;

      if (e.metaKey) {
        result.isMulti = true;
      } else {
        result.isMulti = false;
      }

      e.dataTransfer.setData('text/html', null);
      //e.dataTransfer.effectAllowed = 'move';
      //e.dataTransfer.dropEffect = 'move';

      sendPort('dragstart', result);
    },
    false
  );

  container.addEventListener(
    'dragover',
    function(e) {
      e.preventDefault();
      //e.dataTransfer.effectAllowed = 'move';
      //e.dataTransfer.dropEffect = 'move';
    },
    false
  );

  container.addEventListener(
    'dragend',
    function(e) {
      sendPort('dragend', result);
    },
    false
  );

  container.addEventListener(
    'drop',
    function(e) {
      e.stopPropagation();
      e.preventDefault();
      result.endX = e.clientX;
      result.endY = e.clientY;

      sendPort('drop', result);
    },
    false
  );
}, 1000);

function updateImgPaths(prefix) {
  const images = document.querySelectorAll('img');

  images.forEach(img => {
    console.log(typeof img.src);
    if (img.src.includes('/images')) {
      src = new URL(img.src);
      src.pathname = `${prefix}${src.pathname}`;
      img.src = src.href;
    }
  });
}

function start({ imgPathPrefix }) {
  if (imgPathPrefix) {
    console.log('starting with paths');
    window.onload = () => {
      runApp();
      updateImgPaths(imgPathPrefix);
    };
  } else {
    console.log('starting');
    window.onload = runApp;
  }
}

window.startApp = start;
// board.ports.dragstart.send