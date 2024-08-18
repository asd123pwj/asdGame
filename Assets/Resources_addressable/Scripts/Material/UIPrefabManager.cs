using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;

public struct UIPrefabInfo{
    public string name;
    public string path;
}

public struct UIPrefabsInfo{
    public string version;
    public Dictionary<string, UIPrefabInfo> UIPrefabs;
}

public class UIPrefabManager{
    GameConfigs _game_configs;
    public UIPrefabsInfo _UIPrefabs_info;
    public Dictionary<string, GameObject> _name2UIPrefab = new();

    public UIPrefabManager(GameConfigs game_configs){
        _game_configs = game_configs;
        load_UIPrefabs();
    }

    public bool _check_info_initDone(){
        return !(_UIPrefabs_info.version == null);
    }

    public bool _check_exist(string name){
        return _UIPrefabs_info.UIPrefabs.ContainsKey(name);
    }

    public bool _check_loaded(string name){
        return _name2UIPrefab.ContainsKey(name);
    }

    public GameObject _get_pfb(string name){
        return _name2UIPrefab[name];
    }

    async UniTaskVoid load_UIPrefab(string name){
        string UIPrefab_path = _UIPrefabs_info.UIPrefabs[name].path;
        AsyncOperationHandle<GameObject> handle = Addressables.LoadAssetAsync<GameObject>(UIPrefab_path);
        handle.Completed += action_UIPrefab_loaded;
        await UniTask.Yield();
    }

    void load_UIPrefabs(){
        string jsonText = File.ReadAllText(_game_configs.__UIPrefabsInfo_path);
        _UIPrefabs_info = JsonConvert.DeserializeObject<UIPrefabsInfo>(jsonText);
        foreach (var object_kv in _UIPrefabs_info.UIPrefabs){
            load_UIPrefab(object_kv.Key).Forget();
        }
    }

    void action_UIPrefab_loaded(AsyncOperationHandle<GameObject> handle){
        if (handle.Status == AsyncOperationStatus.Succeeded) _name2UIPrefab.Add(handle.Result.name, handle.Result);
        else Debug.LogError("Failed to load prefab: " + handle.DebugName);
        Addressables.Release(handle);
    }
}
