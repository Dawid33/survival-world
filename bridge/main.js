const fs = require('fs');
const TailingReadableStream = require('tailing-stream');
const PocketBase = require('pocketbase/cjs');

const pb = new PocketBase('https://factoriosurvivalworld.com/db');

if (!process.env.script_output_path) {
  console.log("Must supply script_output_path env variable.");
  return;
}

if (!process.env.db_password) {
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

pb.autoCancellation(false)

const authData = pb.collection("users").authWithPassword(process.env.db_username, process.env.db_password);
let watching_files = {}
fs.watch(process.env.script_output_path, (eventType, filename) => {
  if(!watching_files[filename]) {
    console.log("Starting to watch file ", filename);
    watching_files[filename] = true;
    const stream = TailingReadableStream.createReadStream(process.env.script_output_path + "/" + filename, {timeout: 0});

    let first = true;
    stream.on('data', buffer => {
      // Whole file is read first time it is called.
      if(first) {
        first = false;
        return;
      }

      let value = null;
      try {
        value = JSON.parse(buffer.toString());
      } catch {
        console.log("Failed to parse data: " + buffer.toString())
      }

      try {
        console.log(value)
        if(value.collection && value.method) {
          if(value.collection === "chatlogs") {
              // Get username Id
              if (!value.data.username) {
                console.log("Bad username.")
                return
              }

              const record = pb.collection('factorio_usernames').getFirstListItem(`username="${value.data.username}"`, {}).catch((err) => {
                if(err.status === 404) {
                  return pb.collection('factorio_usernames').create({username: value.data.username})
                } else {
                  return Promise.reject(err);
                }
              }).then((record) => {
                value.data.username_id = record.id;
                delete value.data["username"]
                return pb.collection("chat_logs").create(value.data)
              }).catch(api_failed);
          } else {
              pb.collection(value.collection).create(value.data).catch(api_failed);
          }
        }
      } catch(error){
        console.log("failed to process ", JSON.stringify(value), " because ", error);
      }
    });

    stream.on('close', () => {
      watching_files[filename] = false;
    });
  }
})


