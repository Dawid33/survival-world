const fs = require('fs');
const TailingReadableStream = require('tailing-stream');
const PocketBase = require('pocketbase/cjs');
require('dotenv').config()

const pb = new PocketBase('https://factoriosurvivalworld.com/db');

if (!process.env.script_output_path) {
  console.log("Must supply script_output_path env variable.");
  return;
}

if (!process.env.db_username) {
  console.log("Must supply db_username env variable.");
  return;
}

if (!process.env.db_password) {
  console.log("Must supply db_password env variable.");
  return;
}

function api_failed(err) {
  console.error("Failed api call: ", err);
}

function create_user(err) { }

function create_user(err) {
}

pb.autoCancellation(false)

const authData = pb.collection("users").authWithPassword(process.env.db_username, process.env.db_password);
let watching_files = {}
fs.watch(process.env.script_output_path, (eventType, filename) => {
  if (!watching_files[filename]) {
    console.log("Starting to watch file ", filename);
    watching_files[filename] = true;
    const stream = TailingReadableStream.createReadStream(process.env.script_output_path + "/" + filename, { timeout: 0 });

    let first = true;
    stream.on('data', buffer => {
      // Whole file is read first time it is called.
      if (first) {
        first = false;
        return;
      }

      for (apicall of buffer.toString().split('\n')) {
        if (apicall == "") {
          continue
        }

        let value = null;
        try {
          value = JSON.parse(apicall);
        } catch {
          console.log("Failed to parse data: " + buffer.toString())
        }

        try {
          console.log(value)
          value.data.created_by = pb.authStore.record.id
          if (value.collection && value.method) {
            if (value.collection === "chatlogs") {
              // Get username Id
              if (!value.data.username) {
                console.log("Bad username.")
                return
              }

              const record = pb.collection('factorio_usernames')
                .getFirstListItem(`username="${value.data.username}"`, {})
                .catch((err) => {
                    if (err.status === 404) {
                      return pb.collection('factorio_usernames').create({ username: value.data.username, created_by: value.data.created_by })
                    } else {
                      return Promise.reject(err);
                    }
                  }
                ).then((record) => {
                  value.data.username_id = record.id;
                  delete value.data["username"]
                  return pb.collection("chat_logs").create(value.data)
                })
                .catch(api_failed);
            } else if (value.collection === "player_join_log") {
              // Get username Id
              if (!value.data.username) {
                console.log("Bad username.")
                return
              }

              const record = pb.collection('factorio_usernames').getFirstListItem(`username="${value.data.username}"`, {}).catch((err) => {
                if (err.status === 404) {
                  return pb.collection('factorio_usernames').create({ username: value.data.username, created_by: value.data.created_by })
                } else {
                  return Promise.reject(err);
                }
              }).then((record) => {
                value.data.username_id = record.id;
                delete value.data["username"]
                return pb.collection("player_join_log").create(value.data)
              }).catch(api_failed);
            } else if (value.collection === "games") {
              if (value.data.finished === true) {
                value.data.finished = new Date();
              } else {
                value.data.finished = null;
              }
              console.log(value)

              if (value.method === "update") {
                pb.collection('games').update(value.data.id, value.data).catch(api_failed);
              } else if (value.method === "create") {
                pb.collection('games').create(value.data).catch(api_failed);
              }
            } else {
              pb.collection(value.collection).create(value.data).catch(api_failed);
            }
          }
        } catch (error) {
          console.log("failed to process ", JSON.stringify(value), " because ", error);
        }
      }
    });

    stream.on('close', () => {
      watching_files[filename] = false;
    });
  }
})


