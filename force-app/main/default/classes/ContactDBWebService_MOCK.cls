public class ContactDBWebService_MOCK implements HttpCalloutMock {
    public boolean isOk = true;

    public ContactDBWebService_MOCK() {}

    public ContactDBWebService_MOCK(boolean isOk) {
        this.isOk = isOk;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse response = new HttpResponse();
        
        if (isOk) {
            response.setStatusCode(200);
        } else {
            response.setStatusCode(500);
        }
        
        return response;
    }
}