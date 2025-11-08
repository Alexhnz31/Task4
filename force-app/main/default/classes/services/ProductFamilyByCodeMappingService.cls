public with sharing class ProductFamilyByCodeMappingService {
    
    public static Map<String, String> getProductCodeMapping() {
        
        Map<String, String> productCodeToFamilyMap = new Map<String, String>();
        
        productCodeToFamilyMap.put('Arduino', 'Arduino Board');
        productCodeToFamilyMap.put('SEN010', 'Sensor');
        productCodeToFamilyMap.put('ARD001', 'Arduino Board'); 
        productCodeToFamilyMap.put('TOOL05', 'Tool');
        
        return productCodeToFamilyMap;
    }
}