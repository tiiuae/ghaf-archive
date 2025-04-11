import { S3Client, ListObjectsV2Command } from "@aws-sdk/client-s3";
import { defaultProvider } from "@aws-sdk/credential-provider-node";

const s3 = new S3Client({
  region: "hel1",
  endpoint: "https://hel1.your-objectstorage.com",
  credentials: defaultProvider(),
});

const BUCKET = "ghaf-artifacts";

export async function getS3Versions(): Promise<string[]> {
  const command = new ListObjectsV2Command({
    Bucket: BUCKET,
    Delimiter: "/",
  });

  const result = await s3.send(command);

  const folders = (result.CommonPrefixes || []).map((cp) => cp.Prefix);

  return folders.filter(Boolean) as string[];
}

export async function listFilesInVersion(version: string): Promise<string[]> {
  const prefix = `${version}/`;

  const command = new ListObjectsV2Command({
    Bucket: BUCKET,
    Prefix: prefix,
  });

  const response = await s3.send(command);

  const files = (response.Contents || [])
    .filter((obj) => obj.Key !== prefix) // ignore folder placeholder if any
    .map((obj) => obj.Key!.replace(prefix, "")); // strip prefix to get filename

  return files;
}
