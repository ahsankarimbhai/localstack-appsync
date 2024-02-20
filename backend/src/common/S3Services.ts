import {
  S3Client,
  GetObjectCommand,
  GetObjectOutput,
  ListObjectsV2Command,
  ListObjectsV2CommandInput,
  ListObjectsV2Output,
  DeleteObjectCommand,
  DeleteObjectOutput,
  CopyObjectCommand
} from '@aws-sdk/client-s3';

export class S3Services {
  private readonly s3 = new S3Client();

  constructor(readonly bucketName: string) {
  }

  public getObject(key: string): Promise<GetObjectOutput> {
    return this.s3.send(
      new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key
      })
    );
  }

  /**
   * Returns some or all (up to 1,000) objects in a bucket
   * @param prefix - limits the response to keys that begin with the specified prefix.
   * @param maxKeys - maximum number of keys returned in the response
   * @param continuationToken - indicates Amazon S3 that the list is being continued on this bucket with a token
   */
  listObjects(prefix?: string, maxKeys?: number, continuationToken?: string): Promise<ListObjectsV2Output> {
    return this.s3.send(
      new ListObjectsV2Command({
        Bucket: this.bucketName,
        MaxKeys: maxKeys,
        Prefix: prefix,
        ContinuationToken: continuationToken
      })
    );
  }

  /**
   * Returns all objects in a bucket
   * @param prefix - limits the response to keys that begin with the specified prefix.
   */
  listAllObjects(prefix?: string): Promise<any[]> {
    const allObjects: any[] = [];
    const params = {
      Bucket: this.bucketName,
      Prefix: prefix
    };
    return this.listAllObjectsHelper(params, allObjects);
  }

  /**
   * Removes s3 object
   * @param key - key name of the object to delete
   */
  deleteObject(key: string): Promise<DeleteObjectOutput> {
    return this.s3.send(
      new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key
      })
    );
  }

  /**
   * move s3 object from source to destination
   * @param sourceKey - key name of the source object
   * @param destinationKey - the key of the destination object
   */
  async moveObject(sourceKey: string, destinationKey: string) {
    await this.s3.send(
      new CopyObjectCommand({
        Bucket: this.bucketName,
        CopySource: `${this.bucketName}/${sourceKey}`,
        Key: `${destinationKey}`
      })
    );
    return this.deleteObject(sourceKey);
  }

  private async listAllObjectsHelper(params: ListObjectsV2CommandInput, allObjects: any[]): Promise<any[]> {
    const response = await this.s3.send(new ListObjectsV2Command(params));
    if (!response.Contents || response.Contents.length === 0) {
      return Promise.resolve(allObjects);
    }
    response.Contents.forEach(obj => allObjects.push(obj));
    if (response.NextContinuationToken) {
      params.ContinuationToken = response.NextContinuationToken;
      await this.listAllObjectsHelper(params, allObjects);
    }
    return Promise.resolve(allObjects);
  }
}
