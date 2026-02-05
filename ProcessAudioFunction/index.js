const { BlobServiceClient } = require("@azure/storage-blob");
const ffmpeg = require("fluent-ffmpeg");
const fs = require("fs");
const os = require("os");
const path = require("path");

module.exports = async function (context, event) {
  context.log("EventGrid trigger received:", event);

  const data = event;
  const blobUrl = data.url;

  // Parsiraj container i blob ime iz URL-a
  const parts = blobUrl.split("/");
  const containerName = parts[parts.length - 2];
  const blobName = parts[parts.length - 1];

  // Poveži se na Blob Storage
  const blobServiceClient = BlobServiceClient.fromConnectionString(
    process.env.AzureWebJobsStorage
  );

  const containerClient = blobServiceClient.getContainerClient(containerName);
  const blobClient = containerClient.getBlobClient(blobName);

  // Privremeni fajlovi
  const tmpDir = os.tmpdir();
  const wavPath = path.join(tmpDir, "input.wav");
  const mp3Path = path.join(tmpDir, "output.mp3");

  // Preuzmi WAV fajl
  const downloadResponse = await blobClient.download();
  const buffer = await streamToBuffer(downloadResponse.readableStreamBody);
  fs.writeFileSync(wavPath, buffer);

  // Konvertuj WAV → MP3 + normalizuj
  await new Promise((resolve, reject) => {
    ffmpeg(wavPath)
      .audioFilters("loudnorm")
      .toFormat("mp3")
      .on("end", resolve)
      .on("error", reject)
      .save(mp3Path);
  });

  // Uploaduj MP3 u output container
  const outputContainer = blobServiceClient.getContainerClient("output");
  const outputBlob = outputContainer.getBlockBlobClient(
    blobName.replace(".wav", ".mp3")
  );

  const mp3Buffer = fs.readFileSync(mp3Path);
  await outputBlob.uploadData(mp3Buffer, { overwrite: true });

  context.log("Processed and uploaded MP3:", outputBlob.url);
};

// Helper: stream → buffer
async function streamToBuffer(readableStream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    readableStream.on("data", (data) => {
      chunks.push(data instanceof Buffer ? data : Buffer.from(data));
    });
    readableStream.on("end", () => {
      resolve(Buffer.concat(chunks));
    });
    readableStream.on("error", reject);
  });
}
