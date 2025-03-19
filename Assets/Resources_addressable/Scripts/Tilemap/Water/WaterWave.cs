using UnityEngine;


public class WaterWave : BaseClass{
    public float waveSpeed = 1f;
    public float waveHeight = 20f;
    public float waveFrequency = 1f;
    public int wave_row_start = 2;

    public static Vector3[] vertices_ori_4x4 = new Vector3[25];

    public WaterWave(){
        for (int x = 0; x < 5; x++){
            for (int y = 0; y < 5; y++){
                vertices_ori_4x4[ixy.i(x, y, 5)] = new() { x = x / (5 - 1), y = y / (5 - 1) };
            }
        }
    }
    
    public void _wave(WaterBase water){
        if (water._amount == 0) {
            water._self.SetActive(false);
            return;
        }
        water._self.SetActive(true);
        if (water._isToppest){
            _scale_to_amount(water);
            water._isToppestBefore = true;
            return;
        }
        if (water._isToppestBefore){        // If: Only "toppest before" should recover, cause other have recovered, no need to recover again
            _recover(water);
            water._isToppestBefore = false;
        }
    }

    public void _recover(WaterBase water){
        water.mesh.vertices = vertices_ori_4x4;
        water.mesh.RecalculateNormals();
    }
    
    public void _scale_to_amount(WaterBase water){
        Vector3[] vertices_new = new Vector3[water.mesh.vertices.Length];

        int row = 5;
        int col = 5;
        float height = (float)water._amount / GameConfigs._sysCfg.water_full_amount;

        // ----- Water continuous
        int amount_left, amount_right;
        if (TilemapTile._check_fullTile(water._layer, water._map_pos + Vector3Int.left))
            amount_left = water._amount;
        else
            amount_left = (water._left != null) ? water._left._amount : 0;
        float height_left = (float)amount_left / GameConfigs._sysCfg.water_full_amount;

        if (TilemapTile._check_fullTile(water._layer, water._map_pos + Vector3Int.right))
            amount_right = water._amount;
        else
            amount_right = (water._right != null) ? water._right._amount : 0;
        float height_right = (float)amount_right / GameConfigs._sysCfg.water_full_amount;

        float[] heights = new float[5]{
            height + (height_left - height) / 8 * 3,
            height + (height_left - height) / 8 * 1,
            height,
            height + (height_right - height) / 8 * 1,
            height + (height_right - height) / 8 * 3
        };

        for (int x = 0; x < col; x++){
            for (int y = 0; y < row; y++){
                int i = ixy.i(x, y, col);
                Vector3 vertex = water.mesh.vertices[i];
                vertex.x = (float) x / (col - 1); 
                vertex.y = Mathf.Min((float) y / (row - 1), heights[x]);
                vertices_new[i] = vertex;
            }
        }
        water.mesh.vertices = vertices_new;
        water.mesh.RecalculateNormals();
    }
}
