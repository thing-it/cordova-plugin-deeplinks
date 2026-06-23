/*
Hook executed before the 'prepare' stage. Only for iOS project.
It will check if project name has changed. If so - it will change the name of the .entitlements file to remove that file duplicates.
If file name has no changed - hook will do nothing.
*/

var path = require('path');
var fs = require('fs');
var cordova_ios = require('cordova-ios');

module.exports = function(ctx) {
  run(ctx);
};

/**
 * Run the hook logic.
 *
 * @param {Object} ctx - cordova context object
 */
function run(ctx) {
  var projectRoot = ctx.opts.projectRoot;
  var platformPath = path.join(projectRoot, 'platforms', 'ios');
  var iosProject = new cordova_ios('ios', platformPath);
  var projName = path.basename(iosProject.locations.xcodeCordovaProj);
  var resourcesDir = path.join(iosProject.locations.xcodeCordovaProj, 'Resources');

  var oldEntitlementsFilePath = findAnyEntitlementsFile(resourcesDir);
  if (!oldEntitlementsFilePath) {
    return;
  }

  var desiredEntitlementsPath = path.join(resourcesDir, projName + '.entitlements');
  if (oldEntitlementsFilePath === desiredEntitlementsPath) {
    return;
  }

  console.log('Renaming .entitlements file to match Cordova iOS project name.');

  try {
    fs.renameSync(oldEntitlementsFilePath, desiredEntitlementsPath);
  } catch (err) {
    console.warn('Failed to rename .entitlements file.');
    console.warn(err);
  }
}

// region Private API

/**
 * Find an entitlements file under the given Resources dir.
 *
 * @param {String} resourcesDir absolute path to iOS Resources dir
 * @return {String} absolute path to entitlements file or empty string
 */
function findAnyEntitlementsFile(resourcesDir) {
  var files;
  try {
    files = fs.readdirSync(resourcesDir);
  } catch (err) {
    return '';
  }

  for (var i = 0; i < files.length; i++) {
    if (path.extname(files[i]) === '.entitlements') {
      return path.join(resourcesDir, files[i]);
    }
  }

  return '';
}

// endregion
