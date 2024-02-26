/**
 * @author NGUEV : Nicolas Guevara
 * @date Creation 26/02/2024
 * Webservice to interact with the external ContactDB
 */
public with sharing class ContactDBWebService {

    // TODO : Store the URL in a custom label or custom setting
    public final static String CONTACTDB_API_URL = 'https://fxyozmgb2xs5iogcheotxi6hoa0jdhiz.lambda-url.eu-central-1.on.aws';
    // TODO : Replace static string with custom setting
    public final static String AUTH_TOKEN = 'EXAMPLE_AUTH_TOKEN';

    //Define error codes
    public final static String ERROR_PREFIX = 'ERR_ContactDBWebService';
    public final static String NO_PARAMS = ERROR_PREFIX + '_00_MISSING_PARAMS';
    public final static String SERVER_ERROR = ERROR_PREFIX + '_01_SERVER_ERROR_';

    public class ContactDBRsp {
        public String err;

        public ContactDBRsp(String error) {
            err = error;
        }
    }

    public class ContactWrapper {
        public String id;
        public Boolean is_active;
    }

    /**
     * @author NGUEV : Nicolas Guevara
     * @date Creation 26/02/2024
     * Method to update the contact isActive in the external ContactDB
     * @param ids ids of the contacts to update
     * @param isActive New isActive value of the contacts
     */
    public static ContactDBRsp updateContactsIsActive(List<Id> ids, Boolean isActive) {
        ContactDBRsp contactDBRsp;

        if (ids != null && !ids.isEmpty()) {
            // Create the body to serialize
            List<ContactWrapper> bodyToSerialize = new List<ContactWrapper>();
            for (Id id : ids) {
                ContactWrapper contactWrapper = new ContactWrapper();
                contactWrapper.id = id.toString();
                contactWrapper.is_active = isActive;
                bodyToSerialize.add(contactWrapper);
            }

            // Call the API
            HttpRequest request = new HttpRequest();
            request.setEndpoint(CONTACTDB_API_URL);
            request.setMethod('PATCH');
            request.setHeader('Authorization', AUTH_TOKEN);
            request.setBody(JSON.serialize(bodyToSerialize));
            
            HttpResponse response = new Http().send(request);

            System.debug('ContactDBWebService.updateContactsIsActive - response: ' + response);
            
            switch on response.getStatusCode() {
                when 200 {
                    // Success
                    contactDBRsp = new ContactDBRsp(null);
                }
                when 400 {
                    contactDBRsp = new ContactDBRsp(SERVER_ERROR+'400:' + ' Errors in parameters: must be an array of objects with two properties id:string and is_active:boolean');
                }
                when 401 {
                    contactDBRsp = new ContactDBRsp(SERVER_ERROR+'401:' + ' Bad authorization');
                }
                when 404 {
                    contactDBRsp = new ContactDBRsp(SERVER_ERROR+'404:' + ' Not Found');
                }
                when else {
                    contactDBRsp = new ContactDBRsp(SERVER_ERROR + response.getStatusCode().toString() + ':' + ' An unknown server error occurred');
                }
            }
        } else {
            contactDBRsp = new ContactDBRsp(NO_PARAMS + ':' + 'Missing parameters');
        }

        System.debug('ContactDBWebService.updateContactsIsActive - contactDBRsp: ' + contactDBRsp);

        return contactDBRsp;
    }

}