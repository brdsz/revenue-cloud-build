import { LightningElement, api, wire } from 'lwc';
import getPrimaryQuoteLines from '@salesforce/apex/PrimaryQuoteLinesController.getPrimaryQuoteLines';

const CURRENCY_TYPE = {
    type: 'currency',
    typeAttributes: {
        currencyCode: 'USD',
        minimumFractionDigits: 2
    }
};

export default class PrimaryQuoteLines extends LightningElement {
    @api recordId;

    columns = [
        { label: 'Line', fieldName: 'lineNumber', fixedWidth: 90 },
        { label: 'Product', fieldName: 'productName', wrapText: true },
        { label: 'Code', fieldName: 'productCode', fixedWidth: 130 },
        { label: 'Qty', fieldName: 'quantity', type: 'number', fixedWidth: 90 },
        { label: 'List Price', fieldName: 'listPrice', ...CURRENCY_TYPE },
        { label: 'Unit Price', fieldName: 'unitPrice', ...CURRENCY_TYPE },
        { label: 'Net Unit', fieldName: 'netUnitPrice', ...CURRENCY_TYPE },
        { label: 'Total', fieldName: 'displayTotal', ...CURRENCY_TYPE }
    ];

    response;
    error;

    @wire(getPrimaryQuoteLines, { opportunityId: '$recordId' })
    wiredQuoteLines({ data, error }) {
        this.response = data;
        this.error = error;
    }

    get isLoading() {
        return !this.response && !this.error;
    }

    get hasQuote() {
        return Boolean(this.response?.quoteId);
    }

    get quoteName() {
        return this.response?.quoteName;
    }

    get quoteStatus() {
        return this.response?.quoteStatus;
    }

    get quoteTotal() {
        return this.response?.quoteTotal;
    }

    get lines() {
        return (this.response?.lines || []).map((line) => ({
            ...line,
            displayTotal: line.totalLineAmount ?? line.totalPrice
        }));
    }

    get hasLines() {
        return this.lines.length > 0;
    }

    get emptyMessage() {
        return this.response?.message || 'No primary quote lines to display.';
    }

    get errorMessage() {
        if (!this.error) {
            return undefined;
        }

        return this.error.body?.message || this.error.message || 'Unable to load primary quote lines.';
    }
}
