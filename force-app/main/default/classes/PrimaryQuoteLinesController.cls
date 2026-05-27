public with sharing class PrimaryQuoteLinesController {
    @AuraEnabled(cacheable=true)
    public static PrimaryQuoteLinesResponse getPrimaryQuoteLines(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id is required.');
        }

        Opportunity opportunityRecord = [
            SELECT Id, Name, SyncedQuoteId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        Quote primaryQuote = findPrimaryQuote(opportunityRecord);

        PrimaryQuoteLinesResponse response = new PrimaryQuoteLinesResponse();
        response.opportunityId = opportunityRecord.Id;
        response.opportunityName = opportunityRecord.Name;

        if (primaryQuote == null) {
            response.message = 'No primary quote was found for this opportunity.';
            response.lines = new List<QuoteLineRow>();
            return response;
        }

        response.quoteId = primaryQuote.Id;
        response.quoteName = primaryQuote.Name;
        response.quoteStatus = primaryQuote.Status;
        response.quoteTotal = primaryQuote.GrandTotal;
        response.lines = getQuoteLineRows(primaryQuote.Id);

        if (response.lines.isEmpty()) {
            response.message = 'The primary quote does not have any quote lines.';
        }

        return response;
    }

    private static Quote findPrimaryQuote(Opportunity opportunityRecord) {
        if (opportunityRecord.SyncedQuoteId != null) {
            List<Quote> syncedQuotes = [
                SELECT Id, Name, Status, GrandTotal
                FROM Quote
                WHERE Id = :opportunityRecord.SyncedQuoteId
                LIMIT 1
            ];

            if (!syncedQuotes.isEmpty()) {
                return syncedQuotes[0];
            }
        }

        List<Quote> syncingQuotes = [
            SELECT Id, Name, Status, GrandTotal
            FROM Quote
            WHERE OpportunityId = :opportunityRecord.Id
            AND IsSyncing = true
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        return syncingQuotes.isEmpty() ? null : syncingQuotes[0];
    }

    private static List<QuoteLineRow> getQuoteLineRows(Id quoteId) {
        Map<String, Schema.SObjectField> fieldsByName = QuoteLineItem.SObjectType.getDescribe().fields.getMap();
        List<String> optionalFields = new List<String>{
            'NetUnitPrice',
            'TotalLineAmount',
            'LineNumber'
        };

        List<String> selectedFields = new List<String>{
            'Id',
            'QuoteId',
            'Product2Id',
            'Product2.Name',
            'Product2.ProductCode',
            'Quantity',
            'ListPrice',
            'UnitPrice',
            'TotalPrice'
        };

        for (String fieldName : optionalFields) {
            if (fieldsByName.containsKey(fieldName)) {
                selectedFields.add(fieldName);
            }
        }

        String orderByClause = fieldsByName.containsKey('LineNumber') ? 'LineNumber, CreatedDate' : 'CreatedDate';
        String queryText =
            'SELECT ' + String.join(selectedFields, ', ') +
            ' FROM QuoteLineItem' +
            ' WHERE QuoteId = :quoteId' +
            ' ORDER BY ' + orderByClause;

        List<SObject> quoteLines = Database.query(queryText);
        List<QuoteLineRow> rows = new List<QuoteLineRow>();

        for (SObject quoteLine : quoteLines) {
            rows.add(toQuoteLineRow(quoteLine, fieldsByName));
        }

        return rows;
    }

    private static QuoteLineRow toQuoteLineRow(SObject quoteLine, Map<String, Schema.SObjectField> fieldsByName) {
        QuoteLineRow row = new QuoteLineRow();
        row.id = (Id) quoteLine.get('Id');
        row.productId = (Id) quoteLine.get('Product2Id');
        row.quantity = (Decimal) quoteLine.get('Quantity');
        row.listPrice = (Decimal) quoteLine.get('ListPrice');
        row.unitPrice = (Decimal) quoteLine.get('UnitPrice');
        row.totalPrice = (Decimal) quoteLine.get('TotalPrice');

        if (fieldsByName.containsKey('LineNumber')) {
            Object lineNumberValue = quoteLine.get('LineNumber');
            row.lineNumber = lineNumberValue == null ? null : String.valueOf(lineNumberValue);
        }

        if (fieldsByName.containsKey('NetUnitPrice')) {
            row.netUnitPrice = (Decimal) quoteLine.get('NetUnitPrice');
        }

        if (fieldsByName.containsKey('TotalLineAmount')) {
            row.totalLineAmount = (Decimal) quoteLine.get('TotalLineAmount');
        }

        SObject product = quoteLine.getSObject('Product2');
        if (product != null) {
            row.productName = (String) product.get('Name');
            row.productCode = (String) product.get('ProductCode');
        }

        return row;
    }

    public class PrimaryQuoteLinesResponse {
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String quoteName;
        @AuraEnabled public String quoteStatus;
        @AuraEnabled public Decimal quoteTotal;
        @AuraEnabled public String message;
        @AuraEnabled public List<QuoteLineRow> lines;
    }

    public class QuoteLineRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String lineNumber;
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal netUnitPrice;
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public Decimal totalLineAmount;
    }
}
