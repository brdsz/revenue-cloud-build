@IsTest
private class PrimaryQuoteLinesControllerTest {
    @IsTest
    static void returnsPrimaryQuoteLinesFromSyncedQuote() {
        Account account = new Account(Name = 'Primary Quote Lines Test Account');
        insert account;

        Opportunity opportunity = new Opportunity(
            Name = 'Primary Quote Lines Test Opportunity',
            AccountId = account.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opportunity;

        Product2 product = new Product2(
            Name = 'Primary Quote Lines Test Product',
            ProductCode = 'PQL-001',
            IsActive = true
        );
        insert product;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 25,
            IsActive = true
        );
        insert pricebookEntry;

        Quote quote = new Quote(
            Name = 'Primary Quote Lines Test Quote',
            OpportunityId = opportunity.Id,
            Pricebook2Id = standardPricebook.Id,
            Status = 'Draft'
        );
        insert quote;

        opportunity.SyncedQuoteId = quote.Id;
        update opportunity;

        QuoteLineItem quoteLine = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 2,
            UnitPrice = 25
        );
        insert quoteLine;

        Test.startTest();
        PrimaryQuoteLinesController.PrimaryQuoteLinesResponse response =
            PrimaryQuoteLinesController.getPrimaryQuoteLines(opportunity.Id);
        Test.stopTest();

        System.assertEquals(opportunity.Id, response.opportunityId);
        System.assertEquals(quote.Id, response.quoteId);
        System.assertEquals(1, response.lines.size());
        System.assertEquals(product.Name, response.lines[0].productName);
        System.assertEquals(2, response.lines[0].quantity);
    }

    @IsTest
    static void returnsMessageWhenNoPrimaryQuoteExists() {
        Account account = new Account(Name = 'No Quote Test Account');
        insert account;

        Opportunity opportunity = new Opportunity(
            Name = 'No Quote Test Opportunity',
            AccountId = account.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opportunity;

        Test.startTest();
        PrimaryQuoteLinesController.PrimaryQuoteLinesResponse response =
            PrimaryQuoteLinesController.getPrimaryQuoteLines(opportunity.Id);
        Test.stopTest();

        System.assertEquals(opportunity.Id, response.opportunityId);
        System.assertEquals(null, response.quoteId);
        System.assertEquals(0, response.lines.size());
        System.assertNotEquals(null, response.message);
    }
}
