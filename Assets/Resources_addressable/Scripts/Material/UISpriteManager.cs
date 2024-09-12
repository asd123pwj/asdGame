using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;

public struct UISpriteInfo{
    public string path;
}

public struct UISpritesInfo{
    public string version;
    public Dictionary<string, UISpriteInfo> items;
}

public class UISpriteManager: BaseClass{
    // GameConfigs _GCfg;
    public UISpritesInfo _infos;
    public Dictionary<string, Sprite> _ID2UISprite = new();

    public UISpriteManager(){
        // _GCfg = game_configs;
        load_UISprites();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    public bool _check_exist(string ID){
        return _infos.items.ContainsKey(ID);
    }

    public bool _check_loaded(string ID){
        return _ID2UISprite.ContainsKey(ID);
    }

    public Sprite _get_spr(string ID){
        return _ID2UISprite[ID];
    }

    void load_UISprite(string ID){
        string UISprite_path = _infos.items[ID].path;
        AsyncOperationHandle<Object> handle = Addressables.LoadAssetAsync<Object>(UISprite_path);
        // handle.Completed += action_UISprite_loaded;
        handle.Completed += (operationalHandle) => action_UISprite_loaded(operationalHandle, ID);
    }

    void load_UISprites(){
        string jsonText = File.ReadAllText(_GCfg.__UISpritesInfo_path);
        _infos = JsonConvert.DeserializeObject<UISpritesInfo>(jsonText);
        foreach (var object_kv in _infos.items){
            load_UISprite(object_kv.Key);
        }
    }

    void action_UISprite_loaded(AsyncOperationHandle<Object> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded){
            if (handle.Result is Texture2D texture){
                Sprite sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f));
                _ID2UISprite.Add(ID, sprite);
            }
            else if (handle.Result is TextAsset textAsset){
                SVGParser.SceneInfo sceneInfo = SVGParser.ImportSVG(new System.IO.StringReader(textAsset.text));
                var tessOptions = new VectorUtils.TessellationOptions(){ StepDistance = 0.1f, MaxCordDeviation = 0.1f, MaxTanAngleDeviation = 0.1f, SamplingStepSize = 0.01f};
                var geometry = VectorUtils.TessellateScene(sceneInfo.Scene, tessOptions);
                Sprite sprite = VectorUtils.BuildSprite(geometry, 1.0f, VectorUtils.Alignment.Center, Vector2.zero, 128, true);
                _ID2UISprite.Add(ID, sprite);
            }
            else Debug.LogError("No implement to load type: " + handle.DebugName);
        }
        else Debug.LogError("Failed to load sprite: " + handle.DebugName);
        Addressables.Release(handle);
    }
}
