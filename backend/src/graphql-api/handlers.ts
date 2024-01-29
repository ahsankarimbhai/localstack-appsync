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
};