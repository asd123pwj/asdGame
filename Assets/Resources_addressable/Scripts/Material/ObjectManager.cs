using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;
// using System;

public struct ObjectInfo{
    public string ID;
    public string name;
    public string description;
    public string path;
    public string path_thumbnail;
    public ObjectTags tags;
}

public struct ObjectsInfo{
    public string version;
    public Dictionary<string, ObjectInfo> objects;
}

public class ObjectManager: BaseClass{
    // GameConfigs _GCfg;
    public ObjectsInfo _objects_info;
    public Dictionary<string, AsyncOperationHandle<GameObject>> _name2object = new();
    public Dictionary<string, Sprite> _name2thumbnail = new();


    public ObjectManager(){
        // _GCfg = GCfg;
        load_objects();
    }


    public bool _check_exist(string name){
        return _objects_info.objects.ContainsKey(name);
    }
    public bool _check_info_initDone(){
        return !(_objects_info.version == null);
    }
    public bool _check_prefab_loaded(string name){
        return _name2object.ContainsKey(name);
    }
    public bool _check_thumbnail_loaded(string name){
        return _name2thumbnail.ContainsKey(name);
    }

    public GameObject _get_prefab(string name){
        // Debug.Log(_name2object[name]);
        // Debug.Log(_name2object[name].name);
        // Debug.Log(_name2object[name].layer);
        return _name2object[name].Result;
    }
    public Sprite _get_thumbnail(string name){
        return _name2thumbnail[name];
    }
    public ObjectInfo _get_info(string name){
        return _objects_info.objects[name];
    }

    void load_objects(){
        string jsonText = File.ReadAllText(_GCfg.__objectsInfo_path);
        _objects_info = JsonConvert.DeserializeObject<ObjectsInfo>(jsonText);
        foreach (var object_kv in _objects_info.objects){
            load_prefab(object_kv.Key).Forget();
            load_thumbnail(object_kv.Key).Forget();
        }
    }

    async UniTaskVoid load_prefab(string name){
        string prefab_path = _objects_info.objects[name].path;
        if (prefab_path == null){
            Debug.LogError("Prefab path is null for object: " + name);
            return;
        }
        AsyncOperationHandle<GameObject> handle = Addressables.LoadAssetAsync<GameObject>(prefab_path);
        handle.Completed += (operationHandle) => action_prefab_loaded(operationHandle, name);
        await UniTask.Yield();
    }

    void action_prefab_loaded(AsyncOperationHandle<GameObject> handle, string name){
        if (handle.Status == AsyncOperationStatus.Succeeded)
            _name2object.Add(name, handle);
        else
            Debug.LogError("Failed to load prefab: " + handle.DebugName);
        // Addressables.Release(handle);
    }

    
    async UniTaskVoid load_thumbnail(string name){
        string thumbnail_path = _objects_info.objects[name].path_thumbnail;
        if (thumbnail_path == null){
            Debug.LogError("Thumbnail path is null for object: " + name);
            return;
        }
        AsyncOperationHandle<Object> handle = Addressables.LoadAssetAsync<Object>(thumbnail_path);
        handle.Completed += (operationHandle) => action_thumbnail_loaded(operationHandle, name);
        await UniTask.Yield();
    }
    void action_thumbnail_loaded(AsyncOperationHandle<Object> handle, string name){
        if (handle.Status == AsyncOperationStatus.Succeeded){
            if (handle.Result is Texture2D texture){
                Sprite sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f));
                _name2thumbnail.Add(name, sprite);
            }
            else if (handle.Result is TextAsset textAsset){
                SVGParser.SceneInfo sceneInfo = SVGParser.ImportSVG(new System.IO.StringReader(textAsset.text));
                var tessOptions = new VectorUtils.TessellationOptions(){ StepDistance = 0.1f, MaxCordDeviation = 0.1f, MaxTanAngleDeviation = 0.1f, SamplingStepSize = 0.01f};
                var geometry = VectorUtils.TessellateScene(sceneInfo.Scene, tessOptions);
                Sprite sprite = VectorUtils.BuildSprite(geometry, 1.0f, VectorUtils.Alignment.Center, Vector2.zero, 128, true);
                _name2thumbnail.Add(name, sprite);
            }
        }
        else Debug.LogError("Failed to load prefab: " + name);
        Addressables.Release(handle);
    }
}
