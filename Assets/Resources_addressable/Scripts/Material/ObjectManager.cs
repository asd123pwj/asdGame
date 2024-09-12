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
    public string name;
    public string description;
    public string path;
    public string path_thumbnail;
    public ObjectTags tags;
}

public struct ObjectsInfo{
    public string version;
    public Dictionary<string, ObjectInfo> items;
}

public class ObjectManager: BaseClass{
    public ObjectsInfo _infos;
    public Dictionary<string, AsyncOperationHandle<GameObject>> _ID2object = new();
    public Dictionary<string, Sprite> _ID2thumbnail = new();


    public ObjectManager(){
        load_objects();
    }


    public bool _check_exist(string ID){
        return _infos.items.ContainsKey(ID);
    }
    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }
    public bool _check_prefab_loaded(string ID){
        return _ID2object.ContainsKey(ID);
    }
    public bool _check_thumbnail_loaded(string ID){
        return _ID2thumbnail.ContainsKey(ID);
    }

    public GameObject _get_prefab(string ID){
        return _ID2object[ID].Result;
    }
    public Sprite _get_thumbnail(string ID){
        return _ID2thumbnail[ID];
    }
    public ObjectInfo _get_info(string ID){
        return _infos.items[ID];
    }

    void load_objects(){
        string jsonText = File.ReadAllText(_GCfg.__objectsInfo_path);
        _infos = JsonConvert.DeserializeObject<ObjectsInfo>(jsonText);
        foreach (var object_kv in _infos.items){
            load_item(object_kv.Key);
        }
    }

    void load_item(string ID){
        load_prefab(ID);
        load_thumbnail(ID);
    }


    void load_prefab(string ID){
        string prefab_path = _infos.items[ID].path;
        if (prefab_path == null){
            Debug.LogError("Prefab path is null for object: " + ID);
            return;
        }
        AsyncOperationHandle<GameObject> handle = Addressables.LoadAssetAsync<GameObject>(prefab_path);
        handle.Completed += (operationHandle) => action_prefab_loaded(operationHandle, ID);
    }

    void action_prefab_loaded(AsyncOperationHandle<GameObject> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded)
            _ID2object.Add(ID, handle);
        else
            Debug.LogError("Failed to load prefab: " + handle.DebugName);
    }

    
    void load_thumbnail(string ID){
        string thumbnail_path = _infos.items[ID].path_thumbnail;
        if (thumbnail_path == null){
            Debug.LogError("Thumbnail path is null for object: " + ID);
            return;
        }
        AsyncOperationHandle<Object> handle = Addressables.LoadAssetAsync<Object>(thumbnail_path);
        handle.Completed += (operationHandle) => action_thumbnail_loaded(operationHandle, ID);
    }
    void action_thumbnail_loaded(AsyncOperationHandle<Object> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded){
            if (handle.Result is Texture2D texture){
                Sprite sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f));
                _ID2thumbnail.Add(ID, sprite);
            }
            else if (handle.Result is TextAsset textAsset){
                SVGParser.SceneInfo sceneInfo = SVGParser.ImportSVG(new System.IO.StringReader(textAsset.text));
                var tessOptions = new VectorUtils.TessellationOptions(){ StepDistance = 0.1f, MaxCordDeviation = 0.1f, MaxTanAngleDeviation = 0.1f, SamplingStepSize = 0.01f};
                var geometry = VectorUtils.TessellateScene(sceneInfo.Scene, tessOptions);
                Sprite sprite = VectorUtils.BuildSprite(geometry, 1.0f, VectorUtils.Alignment.Center, Vector2.zero, 128, true);
                _ID2thumbnail.Add(ID, sprite);
            }
        }
        else Debug.LogError("Failed to load prefab: " + ID);
        Addressables.Release(handle);
    }
}
