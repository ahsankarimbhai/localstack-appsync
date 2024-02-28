import { constrainedMemory } from "process";
import { S3Services } from "src/common/S3Services";

/**
 * Fetches PostureEndpoints according to the specified filter.
 * @param event input for fetching endpoints from API GW Authorizer or in the format:
 *   request: {
 *     headers: {
 *       tenantuid: tenant uid, mandatory
 *     }
 *   }
 *   args: {
 *     filter: {
 *       pageNumber: the number of the page to fetch, starts from page 0, optional
 *       producers: array of producers to filter by, optional
 *     }
 *   }
 */
export const listGames = async (event: any) => {
  console.log('in listGames');
  console.log("EVENT\n" + JSON.stringify(event, null, 2))


  // const s3Services = new S3Services('test-bucket');
  // const buckets = await s3Services.listAllObjects();
  // console.log(JSON.stringify(buckets));
  
  return [{
    userId: 1,
    gameId: 1,
    content: "New Game",
    attachment: "SampleLogo.png",
    createdAt: "01-01-2024",
    isActive: false,
  }]
};