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
        if(value.collection && value.method) {
          switch(value.method) {
            case "create":
              const record = pb.collection('test').create(value.data);
              break;
            default:
              break;
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


