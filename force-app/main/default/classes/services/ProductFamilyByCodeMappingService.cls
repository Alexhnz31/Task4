public with sharing class ProductFamilyByCodeMappingService {
    
    private static Map<String, Product_Family_by_Code_Mapping__mdt> mappingCache;

    
    public static Map<String, String> getProductCodeMapping() {
        if (mappingCache == null) {
            mappingCache = Product_Family_by_Code_Mapping__mdt.getAll();
        }

        Map<String, String> productCodeToFamilyMap = new Map<String, String>();
        
        for (Product_Family_by_Code_Mapping__mdt setting : mappingCache.values()) {
            String productCode = setting.Product_Code__c;
            String productFamily = setting.Product_Family__c;
            
            if (String.isNotBlank(productCode)) {
                productCodeToFamilyMap.put(productCode, productFamily);
            }
        }
        return productCodeToFamilyMap;
    }
}