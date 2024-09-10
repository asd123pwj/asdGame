// ref: https://diegogiacomelli.com.br/unitytips-shadowcaster2-from-collider-component/

using UnityEngine;
using UnityEngine.Tilemaps;
using UnityEngine.Rendering.Universal;
using System.Reflection;

public class ShadowGenerator : MonoBehaviour{
    public Tilemap tilemap;
    GameObject _self;
    static readonly FieldInfo _meshField;
    static readonly FieldInfo _shapePathField;
    static readonly MethodInfo _generateShadowMeshMethod;

    static ShadowGenerator(){
        _meshField = typeof(ShadowCaster2D).GetField("m_Mesh", BindingFlags.NonPublic | BindingFlags.Instance);
        _shapePathField = typeof(ShadowCaster2D).GetField("m_ShapePath", BindingFlags.NonPublic | BindingFlags.Instance);

        _generateShadowMeshMethod = typeof(ShadowCaster2D)
                                    .Assembly
                                    .GetType("UnityEngine.Rendering.Universal.ShadowUtility")
                                    .GetMethod("GenerateShadowMesh", BindingFlags.Public | BindingFlags.Static);
    }


    void Start(){
        _generate_shadow();
    }

    public void _generate_shadow(){
        _self = this.gameObject;
        Transform container_old = _self.transform.Find("Container_ShadowCasters");
        if (container_old != null){
            Destroy(container_old.gameObject);
        }
        
        GameObject container = new GameObject("Container_ShadowCasters");
        container.transform.SetParent(_self.transform);

        CompositeCollider2D collider = tilemap.GetComponent<CompositeCollider2D>();
        for (int i = 0; i < collider.pathCount; i++){
            Vector2[] path_vertices = new Vector2[collider.GetPathPointCount(i)];
            Vector3[] points = new Vector3[collider.GetPathPointCount(i)];
            collider.GetPath(i, path_vertices);

            for (int j = 0; j < points.Length; j++){
                points[j] = new Vector3(path_vertices[j].x, path_vertices[j].y, 0);
            }

            GameObject obj = new("ShadowCasters_" + i);
            obj.transform.SetParent(container.transform);

            ShadowCaster2D shadowCaster = obj.AddComponent<ShadowCaster2D>();
            shadowCaster.selfShadows = true;
            _shapePathField.SetValue(shadowCaster, points);
            _meshField.SetValue(shadowCaster, new Mesh());
            _generateShadowMeshMethod.Invoke(shadowCaster, new object[] { _meshField.GetValue(shadowCaster), _shapePathField.GetValue(shadowCaster) });

        }

    }
}

