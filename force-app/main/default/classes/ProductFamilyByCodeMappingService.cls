public with sharing class ProductFamilyByCodeMappingService {
    
    /**
     * Возвращает статическую карту соответствия Product Code и Product Family.
     * Заменяет логику чтения Custom Metadata Type.
     */
    public static Map<String, String> getProductCodeMapping() {
        
        Map<String, String> productCodeToFamilyMap = new Map<String, String>();
        
        // ВНИМАНИЕ: ЗДЕСЬ НУЖНО ПРОПИСАТЬ ВАШИ АКТУАЛЬНЫЕ КОДЫ И СЕМЕЙСТВА
        // Если у вас тысячи значений, этот подход не рекомендуется (лучше CMDT/Custom Settings)
        // Но для небольшого количества - это рабочий обходной путь.
        
        // Пример хардкодинга:
        productCodeToFamilyMap.put('ARD001', 'Arduino Board');
        productCodeToFamilyMap.put('ARD002', 'Arduino Board');
        productCodeToFamilyMap.put('SEN010', 'Sensor');
        productCodeToFamilyMap.put('TOOL05', 'Tool');
        
        // Предполагается, что 'Product_Code__c' и 'Product_Family__c' 
        // из вашего старого CMDT давали эти пары:
        // productCodeToFamilyMap.put(<Product_Code__c>, <Product_Family__c>);
        
        return productCodeToFamilyMap;
    }
}