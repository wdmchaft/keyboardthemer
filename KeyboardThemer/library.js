/*
 * Copyright 2009 Dominic Cooney.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 */

// The built-in library for JavaScript effects. There are just two host objects:
// a __getColor__ and a __setColor__ function. The public JavaScript API is
// defined in this file.

// The 'keys' object.
const keys = {};

(function () {
 
function truncate(value) {
  return Math.min(1.0, Math.max(0.0, value)) || 0.0;
}

// Creates a color object with r, g, b and a properties between 0.0 and 1.0,
// either from HTML-style #rrggbbaa triples or quadrules, or objects with
// r, g, b and a properties.
function Color(values) {
  var parts;
  if ((parts = String(values).match(Color.pattern))) {
    return {
      r: truncate(parseInt(parts[1], 16)),
      g: truncate(parseInt(parts[2], 16)),
      b: truncate(parseInt(parts[3], 16)),
      a: truncate(parseInt(
             String(typeof parts[4]) == 'undefined' ? 1.0 : parts[4],
             16))
    };
  } else {
    values = values || {};
    return {
      r: truncate(values.r),
      g: truncate(values.g),
      b: truncate(values.b),
      a: truncate('a' in values ? values.a : 1.0)
    };
  }
}
Color.pattern =
    /#?([a-fA-F0-9]{2})([a-fA-F0-9]{2})([a-fA-F0-9]{2})([a-fA-F0-9]{2})?/;

// Maps human-readable key names like 'Tab' to their indexes in the
// KeyboardThemer bitmap.
keys.names = {
  '~': 0x32,
  '1': 0x12,
  '2': 0x13,
  '3': 0x14,
  '4': 0x15,
  '5': 0x17,
  '6': 0x16,
  '7': 0x1a,
  '8': 0x1c,
  '9': 0x19,
  '0': 0x1d,
  '-': 0x1b,
  '=': 0x18,
  'Backspace': 0x33,
  'Tab': 0x30,
  'Q': 0x0c,
  'W': 0x0d,
  'E': 0x0e,
  'R': 0x0f,
  'T': 0x11,
  'Y': 0x10,
  'U': 0x20,
  'I': 0x22,
  'O': 0x1f,
  'P': 0x23,
  '[': 0x21,
  ']': 0x1e,
  '\\': 0x2a,
  'CapsLock': 0x39,
  'A': 0x00,
  'S': 0x01,
  'D': 0x02,
  'F': 0x03,
  'G': 0x05,
  'H': 0x04,
  'J': 0x26,
  'K': 0x28,
  'L': 0x25,
  ';': 0x29,
  '\'': 0x27,
  'Enter': 0x24,
  'LeftShift': 0x38,
  'Z': 0x06,
  'X': 0x07,
  'C': 0x08,
  'V': 0x09,
  'B': 0x0b,
  'N': 0x2d,
  'M': 0x2e,
  ',': 0x2b,
  '.': 0x2f,
  '/': 0x2c,
  'RightShift': 0x3c,
  'LeftCtrl': 0x3b,
  'LeftVendor': 0x37,
  'LeftAlt': 0x3a,
  'RightAlt': 0x3d,
  'RightVendor': 0x36,
  'RightMenu': 0x6e,
  'RightCtrl': 0x3e,
  'Home': 0x73,
  'PgUp': 0x74,
  'Delete': 0x75,
  'End': 0x77,
  'PgDn': 0x79,
  'Left': 0x7b,
  'Right': 0x7c,
  'Down': 0x7d,
  'Up': 0x7e
};
 
for (var keyName in keys.names) {
  keys.__defineGetter__(
    keyName,
    (function (keyCode) {
      return function () {
        return __getColor__(keyCode);
      };                    
    })(keys.names[keyName]));
  keys.__defineSetter__(
    keyName,
    (function (keyCode) {
      return function (color) {
        color = Color(color);
        __setColor__(keyCode, color.r, color.g, color.b, color.a);
     };                         
    })(keys.names[keyName]));
}

function blend(c1, c2) {
  return {
    r: c2.r * c2.a + c1.r * (1.0 - c2.a),
    g: c2.g * c2.a + c1.g * (1.0 - c2.a),
    b: c2.b * c2.a + c1.b * (1.0 - c2.a),
    a: Math.min(1.0, c1.a + c2.a)
  };
}

// Paints the specified color on the specified keys. If the specified color is
// translucent it is blended with the existing colors of the specified keys.
keys.paint = function(color, varargs) {
  color = Color(color);
  for (var i = 1; i < arguments.length; i++) {
    var keyName = arguments[i];
    var existingColor = keys[keyName];
    keys[keyName] = blend(existingColor, color);
  }
}

// Makes all of the keys opaque black. If a color is specified makes all of the
// keys that color instead.
keys.clear = function(opt_color) {
  var color = Color(opt_color || {});
  for (var keyName in keys.names) {
    keys[keyName] = color;
  }
}
 
})();