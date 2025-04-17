import { S3Client, ListObjectsV2Command } from "@aws-sdk/client-s3";
import { defaultProvider } from "@aws-sdk/credential-provider-node";
import { S3_BUCKET, S3_REGION, S3_ENDPOINT } from "./constants";

const s3 = new S3Client({
  region: S3_REGION,
  endpoint: `https://${S3_REGION}.${S3_ENDPOINT}`,
  credentials: defaultProvider(),
});

export async function getGhafReleases(): Promise<string[]> {
  const command = new ListObjectsV2Command({
    Bucket: S3_BUCKET,
    Delimiter: "/",
  });

  const result = await s3.send(command);

  const folders = (result.CommonPrefixes || []).map((cp) => cp.Prefix?.split('/')[0]);

  folders.sort().reverse();
  return folders.filter(Boolean) as string[];
}

export async function getArtifactsInRelease(version: string): Promise<string[]> {
  const prefix = `${version}/`;

  const command = new ListObjectsV2Command({
    Bucket: S3_BUCKET,
    Prefix: prefix,
  });

  const response = await s3.send(command);

  const files = (response.Contents || [])
    .filter((obj) => obj.Key !== prefix) // ignore folder placeholder if any
    .map((obj) => obj.Key!.replace(prefix, "")); // strip prefix to get filename

  files.sort();
  return files;
}
