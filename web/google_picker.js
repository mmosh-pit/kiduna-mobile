/**
 * Google Drive Picker helpers for Kiduna Mobile.
 *
 * Two functions exposed to Dart via js_interop:
 *   googleSignIn(clientId, callback)  — OAuth token via GIS popup
 *   googlePickFiles(token, apiKey, callback) — Drive Picker file selection
 */

// ── Sign-in via Google Identity Services ──

let _tokenClient = null;
let _signInCallback = null;

/**
 * Request an OAuth2 access token via the GIS popup.
 * @param {string} clientId  — Google OAuth client ID
 * @param {function} callback — called with {token} or {error}
 */
function googleSignIn(clientId, callback) {
  _signInCallback = callback;

  if (!window.google || !window.google.accounts) {
    callback({ error: 'Google Identity Services not loaded' });
    return;
  }

  _tokenClient = google.accounts.oauth2.initTokenClient({
    client_id: clientId,
    scope: 'https://www.googleapis.com/auth/drive.readonly',
    callback: function (response) {
      if (response.error) {
        _signInCallback({ error: response.error });
      } else {
        _signInCallback({ token: response.access_token });
      }
    },
    error_callback: function (err) {
      _signInCallback({ error: err.message || 'Sign-in cancelled' });
    },
  });

  _tokenClient.requestAccessToken();
}

// ── Google Drive Picker ──

let _pickerLoaded = false;

/**
 * Open the Google Drive file picker.
 * @param {string} token   — OAuth access token
 * @param {string} apiKey  — Google API key (for Picker)
 * @param {function} callback — called with {files: [{id, name, mimeType}]} or {error}
 */
function googlePickFiles(token, apiKey, callback) {
  if (!window.google || !window.google.accounts) {
    callback({ error: 'Google APIs not loaded' });
    return;
  }

  function showPicker() {
    const supportedMimeTypes = [
      'application/pdf',
      'text/plain',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.google-apps.document',
      'application/vnd.google-apps.folder',
    ].join(',');

    const docsView = new google.picker.DocsView()
      .setIncludeFolders(true)
      .setSelectFolderEnabled(true)
      .setMimeTypes(supportedMimeTypes);

    const picker = new google.picker.PickerBuilder()
      .addView(docsView)
      .setOAuthToken(token)
      .setDeveloperKey(apiKey)
      .enableFeature(google.picker.Feature.MULTISELECT_ENABLED)
      .setCallback(function (data) {
        if (data.action === google.picker.Action.PICKED) {
          const files = data.docs.map(function (doc) {
            return {
              id: doc.id,
              name: doc.name,
              mimeType: doc.mimeType,
            };
          });
          callback({ files: files });
        } else if (data.action === google.picker.Action.CANCEL) {
          callback({ files: [] });
        }
      })
      .build();

    picker.setVisible(true);
  }

  if (_pickerLoaded) {
    showPicker();
  } else {
    gapi.load('picker', {
      callback: function () {
        _pickerLoaded = true;
        showPicker();
      },
      onerror: function () {
        callback({ error: 'Failed to load Google Picker' });
      },
    });
  }
}