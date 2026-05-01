import xml.etree.ElementTree as ET
import csv
import sys

def convert_xml_to_csv(xml_path, csv_path):
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        
        with open(csv_path, 'w', encoding='utf-8', newline='') as f:
            writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
            
            for folder in root.findall('folder'):
                folder_title = folder.find('title').text or ""
                
                snippets_node = folder.find('snippets')
                if snippets_node is not None:
                    for snippet in snippets_node.findall('snippet'):
                        snippet_title = snippet.find('title').text or ""
                        snippet_content = snippet.find('content').text or ""
                        
                        writer.writerow([folder_title, snippet_title, snippet_content])
        
        print(f"Successfully converted {xml_path} to {csv_path}")
        return True
    except Exception as e:
        print(f"Error during conversion: {e}")
        return False

if __name__ == "__main__":
    xml_file = "/Users/cocone/自社PJ_local/Qlypx/Resources/snippets.xml"
    csv_file = "/Users/cocone/自社PJ_local/Qlypx/Resources/snippets.csv"
    convert_xml_to_csv(xml_file, csv_file)
