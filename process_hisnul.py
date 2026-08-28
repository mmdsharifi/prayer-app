import json
import time
import re
import traceback
from deep_translator import GoogleTranslator

# Numbers mapping for counts
counts_map = {
    'one time': 1, 'once': 1,
    'two times': 2, 'twice': 2,
    'three times': 3, '3 times': 3,
    'four times': 4, '4 times': 4,
    'seven times': 7, '7 times': 7,
    'ten times': 10, '10 times': 10,
    'thirty three times': 33, '33 times': 33, 'thirty-three times': 33,
    'thirty four times': 34, '34 times': 34, 'thirty-four times': 34,
    'one hundred times': 100, '100 times': 100, 'a hundred times': 100, 'hundred times': 100
}

def extract_count(text):
    text_lower = text.lower()
    best_count = 1
    for pattern, count in counts_map.items():
        if pattern in text_lower:
            # simple heuristic: take the largest count found, or just the first
            if count > best_count:
                best_count = count
    return best_count

def translate_safe(text, target_lang):
    if not text.strip():
        return ""
    for attempt in range(5):
        try:
            return GoogleTranslator(source='auto', target=target_lang).translate(text)
        except Exception as e:
            if "429" in str(e):
                time.sleep(2 ** attempt)
            else:
                print(f"Error translating: {e}")
                time.sleep(1)
    return text # fallback

with open('hisnulmuslim_grouped.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for ch_idx, chapter in enumerate(data):
    ch_name = chapter.get('chapter_name', chapter.get('chapter_title', ''))
    chapter['chapter_name_fa'] = translate_safe(ch_name, 'fa')
    chapter['chapter_name_ku'] = translate_safe(ch_name, 'ckb')
    chapter['total_zikrs'] = len(chapter['zikrs'])
    
    for z_idx, zikr in enumerate(chapter['zikrs']):
        zikr['id'] = f"ch{ch_idx}_z{z_idx}"
        zikr['count'] = extract_count(zikr.get('english', ''))
        
        ar_text = zikr.get('arabic', '')
        zikr['fa'] = translate_safe(ar_text, 'fa')
        zikr['ku'] = translate_safe(ar_text, 'ckb')
    
    print(f"Processed chapter {ch_idx+1}/{len(data)}")

import os
os.makedirs('prayer_app/assets', exist_ok=True)
with open('prayer_app/assets/hisnulmuslim_enriched.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Done")
