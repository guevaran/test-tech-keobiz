public without sharing class AccountTriggerHelper {
    public AccountTriggerHelper() {}

    /**
     * @author NGUEV : Nicolas Guevara
     * @date Creation 26/02/2024
     * Call Webservice of external ContactDB to send the contact inactive information
     */
    @future(callout=true)
    public static void sendContactInactiveInfo(List<Id> contactIds) {
        ContactDBWebService.ContactDBRsp rsp = ContactDBWebService.updateContactsIsActive(contactIds, false);
        if (String.isNotBlank(rsp.err)) {
            System.debug('Error in sendContactInactiveInfo: ' + rsp.err);
        }
    }
}