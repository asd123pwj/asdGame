

using System.IO;
using System.Collections.Generic;
using UnityEngine;
using Newtonsoft.Json;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;

public struct SpriteMaterialInfo{
    public string name;
    public string sprite;
    public string material;
};

public struct SpriteMaterialsInfo{
    public string version;
    public Dictionary<string, SpriteMaterialInfo> items;
}

public class SpriteMaterialPreprocessor: BaseClass{
    public SpriteMaterialsInfo _infos;
    public Dictionary<string, Dictionary<string, Material>> _ID_to_subID2SpriteMaterials = new();

    public SpriteMaterialPreprocessor(){
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    // ---------- mapping ----------
    public Material _get_mat(string ID, string subID){
        if (ID == "0") return null; // No sprite
        if (_ID_to_subID2SpriteMaterials.ContainsKey(ID) && _ID_to_subID2SpriteMaterials[ID].ContainsKey(subID)) return _ID_to_subID2SpriteMaterials[ID][subID]; // Sprite have been loaded
        return null; // !!! 记得更新默认sprite。Can't find sprite, return missing placeholder
    }

    public SpriteMaterialInfo _get_info(string ID){
        return _infos.items[ID];
    }
    public bool _check_loaded(string ID, string subID){
        return _ID_to_subID2SpriteMaterials[ID].ContainsKey(subID);
    }
    
    // ---------- config ----------
    bool check_resources_loaded(string ID){
        if (_sys == null) return false;
        if (_sys._MatSys == null) return false;
        SpriteMaterialInfo info = _infos.items[ID];
        if (!_sys._MatSys._check_all_info_initDone()) return false;
        if (!_sys._MatSys._mat._check_loaded(info.material)) return false;
        if (!_sys._MatSys._spr._check_loaded(info.sprite)) return false;
        return true;
    }

    void load_items(){
        string jsonText = File.ReadAllText(_GCfg.__SpriteMaterialsInfo_path);
        _infos = JsonConvert.DeserializeObject<SpriteMaterialsInfo>(jsonText);
        foreach (var tile_kv in _infos.items){
            load_item(tile_kv.Key).Forget();
        }
    }

    async UniTaskVoid load_item(string ID){
        SpriteMaterialInfo info = _infos.items[ID];
        while (!check_resources_loaded(ID)){
            // Debug.Log("wait");
            await UniTask.Delay(100);
        }
        string[] subIDs = _sys._MatSys._spr._get_info(info.sprite).sprites;
        _ID_to_subID2SpriteMaterials.Add(ID, new());
        foreach (string subID in subIDs){
            Sprite sprite = _sys._MatSys._spr._get_sprite(ID, subID);
            Material material= new(_sys._MatSys._mat._get_mat(info.material)){
                mainTexture = sprite.texture,
                mainTextureOffset = new Vector2(sprite.rect.x / sprite.texture.width, sprite.rect.y / sprite.texture.height),
                mainTextureScale = new Vector2(sprite.rect.width / sprite.texture.width, sprite.rect.height / sprite.texture.height)
            };
            _ID_to_subID2SpriteMaterials[ID].Add(subID, material);
        }
    }



}
