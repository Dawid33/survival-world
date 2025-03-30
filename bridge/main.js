const fs = require('fs');

if (!process.env.script_output_path) {
  console.log("Must supply script_output_path env variable.");
  return   
}

while(!fs.existsSync(""))

const TailingReadableStream = require('tailing-stream');
const stream = TailingReadableStream.createReadStream("../../../script-output/testing.txt", {timeout: 0});
stream.on('data', buffer => {
  console.log(buffer.toString());
});

stream.on('close', () => {
  console.log("close");
});

