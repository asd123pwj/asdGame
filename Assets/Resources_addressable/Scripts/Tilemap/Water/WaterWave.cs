using UnityEngine;


public class WaterWave : BaseClass{
    public float waveSpeed = 1f;
    public float waveHeight = 20f;
    public float waveFrequency = 1f;
    public int wave_row_start = 2;

    // ----- P3D
    float P3D_scale = 1.5f; // 1.5f is for P3D, 1 is front, 0.5 is up/side
    float h1 = .25f; // 1 / 6 * 1.5f
    float h2 = .5f; // 2 / 6 * 1.5f
    float w1 = .25f; // 1 / 6 * 1.5f
    float w2 = .5f; // 2 / 6 * 1.5f

    // public static Vector3[] vertices_ori_4x4 = new Vector3[25];
    public static Vector3[] vertices_ori_6x6_frontOnly = new Vector3[49];
    public static Vector3[] vertices_ori_6x6_frontSide = new Vector3[49];

    public WaterWave(){
        // for (int x = 0; x < 5; x++){
        //     for (int y = 0; y < 5; y++){
        //         vertices_ori_4x4[ixy.i(x, y, 5)] = new() { x = (float)x / (5 - 1) * P3D_scale, y = (float)y / (5 - 1) * P3D_scale }; 
        //     }
        // }
        for (int x = 0; x < 7; x++){
            for (int y = 0; y < 7; y++){
                int x_ = Mathf.Min(x, 5 - 1); // remove P3D point
                int y_ = Mathf.Min(y, 5 - 1); // remove P3D point
                vertices_ori_6x6_frontOnly[ixy.i(x_, y_, 7)] = new() { x = (float)x_ / (7 - 1) * P3D_scale, y = (float)y_ / (7 - 1) * P3D_scale }; 
            }
        }
        vertices_ori_6x6_frontSide = (Vector3[])vertices_ori_6x6_frontOnly.Clone();
        int col = 7;
        // ----- Up ----- //
        vertices_ori_6x6_frontSide[ixy.i(0, 5, col)] = vertices_ori_6x6_frontSide[ixy.i(0, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(0, 6, col)] = vertices_ori_6x6_frontSide[ixy.i(0, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(1, 5, col)] = vertices_ori_6x6_frontSide[ixy.i(1, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(1, 6, col)] = vertices_ori_6x6_frontSide[ixy.i(1, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(2, 5, col)] = vertices_ori_6x6_frontSide[ixy.i(2, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(2, 6, col)] = vertices_ori_6x6_frontSide[ixy.i(2, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(3, 5, col)] = vertices_ori_6x6_frontSide[ixy.i(3, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(3, 6, col)] = vertices_ori_6x6_frontSide[ixy.i(3, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(4, 5, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(4, 6, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 4, col)];
        vertices_ori_6x6_frontSide[ixy.i(5, 5, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 4, col)] + new Vector3(w1, h1, 0);
        vertices_ori_6x6_frontSide[ixy.i(5, 6, col)] = vertices_ori_6x6_frontSide[ixy.i(5, 5, col)];
        vertices_ori_6x6_frontSide[ixy.i(6, 6, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 4, col)] + new Vector3(w2, h2, 0);
        
        // ----- Side ----- //
        vertices_ori_6x6_frontSide[ixy.i(5, 0, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 0, col)];
        vertices_ori_6x6_frontSide[ixy.i(6, 0, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 0, col)];
        vertices_ori_6x6_frontSide[ixy.i(5, 1, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 0, col)] + new Vector3(w1, h1, 0);
        vertices_ori_6x6_frontSide[ixy.i(6, 1, col)] = vertices_ori_6x6_frontSide[ixy.i(5, 1, col)];
        vertices_ori_6x6_frontSide[ixy.i(5, 2, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 1, col)] + new Vector3(w1, h1, 0);
        vertices_ori_6x6_frontSide[ixy.i(6, 2, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 0, col)] + new Vector3(w2, h2, 0);
        vertices_ori_6x6_frontSide[ixy.i(5, 3, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 2, col)] + new Vector3(w1, h1, 0);
        vertices_ori_6x6_frontSide[ixy.i(6, 3, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 2, col)] + new Vector3(w2, h2, 0);
        vertices_ori_6x6_frontSide[ixy.i(5, 4, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 3, col)] + new Vector3(w1, h1, 0);
        vertices_ori_6x6_frontSide[ixy.i(6, 4, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 3, col)] + new Vector3(w2, h2, 0);
        vertices_ori_6x6_frontSide[ixy.i(6, 5, col)] = vertices_ori_6x6_frontSide[ixy.i(4, 4, col)] + new Vector3(w2, h2, 0);

    }
    
    public void _wave(WaterBase water){
        if (water._amount == 0) {
            water._self.SetActive(false);
            return;
        }
        water._self.SetActive(true);
        //             _recover(water);
        // return;

        // if (water._isToppest){
        //     WaterBase._texture._update_mesh_6x6(water);

        // }
        if (water._isToppest){
            _scale_to_amount(water);
            water._textureStatus = WaterTextureStatus.Normal;
            return;
        }
        // if (water._textureStatus){        // If: Only "toppest before" should recover, cause other have recovered, no need to recover again
            // WaterBase._texture._update_mesh_4x4(water);
        _recover(water);
        // water._textureStatus = false;
        // }
    }

    public void _recover(WaterBase water){
        if (water._right == null || water._right._amount == 0){
            // if (water._textureStatus == WaterTextureStatus.FrontSide) return;
            water.mesh.vertices = vertices_ori_6x6_frontSide;
            water._textureStatus = WaterTextureStatus.FrontSide;
            water.mesh.RecalculateNormals();
        }
        else{
            // if (water._textureStatus == WaterTextureStatus.Front) return;
            water.mesh.vertices = vertices_ori_6x6_frontOnly;
            water._textureStatus = WaterTextureStatus.Front;
            water.mesh.RecalculateNormals();
        }
    }
    
    public void _scale_to_amount(WaterBase water){
        Vector3[] vertices_new = new Vector3[water.mesh.vertices.Length];

        int row_front = 5, col_front = 5; // Front
        int row = 7, col = 7;             // Full, i.e., Front + Up + Side

        // ----- Water continuous
        int amount_left, amount_right;
        if (TilemapTile._check_fullTile(water._layer, water._map_pos + Vector3Int.left))
            amount_left = water._amount;
        else
            amount_left = (water._left != null) ? water._left._amount : 0;

        if (TilemapTile._check_fullTile(water._layer, water._map_pos + Vector3Int.right))
            amount_right = water._amount;
        else
            amount_right = (water._right != null) ? water._right._amount : 0;

        float height = (float)water._amount / GameConfigs._sysCfg.water_full_amount;
        float height_left = (float)amount_left / GameConfigs._sysCfg.water_full_amount;
        float height_right = (float)amount_right / GameConfigs._sysCfg.water_full_amount;

        // ---------- Water P3D ---------- //
        bool have_water_right = water._right != null && water._right._amount > 0;
        float[,,] P3D_offset = new float[7, 7, 2];
        // float[,] P3D_offset = new float[7, 7];
        // ----- Up ----- //
        // for (int x = 0; x < col; x++){
        //     for (int y = row_front; y < row; y++){
        //         if (y < x) continue;
        //         if (x >= col_front) P3D_offset[x, y, 0] = (float)(x - col_front + 1) / (col - 1);
        //         else                P3D_offset[x, y, 0] = 0;
        //         P3D_offset[x, y, 1] = (float)(y - row_front + 1) / (row - 1);
        //     }
        // }
        
        // P3D_offset[0, 5, 0] = 0;  P3D_offset[0, 5, 1] = 0;
        // P3D_offset[0, 6, 0] = 0;  P3D_offset[0, 6, 1] = 0;
        // P3D_offset[1, 5, 0] = 0;  P3D_offset[1, 5, 1] = h1;
        // P3D_offset[1, 6, 0] = 0;  P3D_offset[1, 6, 1] = h1; // real h5, not h6
        // P3D_offset[2, 5, 0] = 0;  P3D_offset[2, 5, 1] = h1;
        // P3D_offset[2, 6, 0] = 0;  P3D_offset[2, 6, 1] = h2;
        // P3D_offset[3, 5, 0] = 0;  P3D_offset[3, 5, 1] = h1;
        // P3D_offset[3, 6, 0] = 0;  P3D_offset[3, 6, 1] = h2;
        // P3D_offset[4, 5, 0] = 0;  P3D_offset[4, 5, 1] = h1;
        // P3D_offset[4, 6, 0] = 0;  P3D_offset[4, 6, 1] = h2;
        // P3D_offset[5, 5, 0] = 0; P3D_offset[5, 5, 1] = h1;
        // P3D_offset[5, 6, 0] = 0; P3D_offset[5, 6, 1] = h2;
        // // P3D_offset[6, 5, 0] = w6; P3D_offset[6, 5, 1] = h5;
        // P3D_offset[6, 6, 0] = 0; P3D_offset[6, 6, 1] = h2;
        // P3D_offset[1, 6, 1] = 1f / (row - 1);
        // ----- Side ----- //
        // for (int x = col_front; x < col; x++){
        //     for (int y = 0; y < row; y++){
        //         if (y >= x) continue;
        //         if (have_water_right){
        //             if (y == 5 && x == 6) P3D_offset[x, y, 0] = 1f / (col - 1);
        //             else                  P3D_offset[x, y, 0] = 0;
        //         }
        //         else                      P3D_offset[x, y, 0] = (float)(x - col_front + 1) / (col - 1);
        //         if (y == 5) P3D_offset[x, y, 1] = (float)(y - row_front + 1) / (row - 1);
        //         else        P3D_offset[x, y, 1] = 0;
        //     }
        // }
        // float W5 = have_water_right ? -w1 : 0;
        // float W6 = have_water_right ? -w2 : 0;
        // P3D_offset[5, 0, 0] = 0;  P3D_offset[5, 0, 1] = 0;
        // P3D_offset[6, 0, 0] = 0;  P3D_offset[6, 0, 1] = 0;
        // P3D_offset[5, 1, 0] = W5;  P3D_offset[5, 1, 1] = 0;
        // P3D_offset[6, 1, 0] = W6;  P3D_offset[6, 1, 1] = 0;
        // P3D_offset[5, 2, 0] = W5;  P3D_offset[5, 2, 1] = 0;
        // P3D_offset[6, 2, 0] = W6;  P3D_offset[6, 2, 1] = 0;
        // P3D_offset[5, 3, 0] = W5;  P3D_offset[5, 3, 1] = 0;
        // P3D_offset[6, 3, 0] = W6;  P3D_offset[6, 3, 1] = 0;
        // P3D_offset[5, 4, 0] = W5;  P3D_offset[5, 4, 1] = 0;
        // P3D_offset[6, 4, 0] = W6;  P3D_offset[6, 4, 1] = 0;
        // // P3D_offset[5, 5, 0] = w5;  P3D_offset[5, 5, 1] = 0;
        // P3D_offset[6, 5, 0] = W6;  P3D_offset[6, 5, 1] = h2;

        // ----- Water wave

        float[] heights = new float[5]{
            height + (height_left  - height) / 8 * 4,
            height + (height_left  - height) / 8 * 1,
            height,
            height + (height_right - height) / 8 * 1,
            height + (height_right - height) / 8 * 4
        };


        // ----- Front ----- //
        float x_, y_;
        for (int x = 0; x < col_front; x++){
            for (int y = 0; y < row_front; y++){
                int i = ixy.i(x, y, col);
                Vector3 vertex = water.mesh.vertices[i];
                x_ = (float)x / (col - 3); // col - 1 is normalization, col - 1 - 2 is P3D normalization
                // x_ = Mathf.Min(x_, 4.0f / 6.0f);
                y_ = (float)y / (row - 3);
                y_ = Mathf.Min(y_, heights[x]);
                vertex.x = x_ ; 
                vertex.y = y_ ;
                vertices_new[i] = vertex;
            }
        }
        // ----- Up ----- //
        vertices_new[ixy.i(0, 5, col)] = vertices_new[ixy.i(0, 4, col)];
        vertices_new[ixy.i(0, 6, col)] = vertices_new[ixy.i(0, 4, col)];
        vertices_new[ixy.i(1, 5, col)] = vertices_new[ixy.i(0, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(1, 6, col)] = vertices_new[ixy.i(1, 5, col)];
        vertices_new[ixy.i(2, 5, col)] = vertices_new[ixy.i(1, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(2, 6, col)] = vertices_new[ixy.i(0, 4, col)] + new Vector3(w2, h2, 0);
        vertices_new[ixy.i(3, 5, col)] = vertices_new[ixy.i(2, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(3, 6, col)] = vertices_new[ixy.i(1, 4, col)] + new Vector3(w2, h2, 0);
        vertices_new[ixy.i(4, 5, col)] = vertices_new[ixy.i(3, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(4, 6, col)] = vertices_new[ixy.i(2, 4, col)] + new Vector3(w2, h2, 0);
        vertices_new[ixy.i(5, 5, col)] = vertices_new[ixy.i(4, 4, col)] + new Vector3(w1, h1, 0);
        vertices_new[ixy.i(5, 6, col)] = vertices_new[ixy.i(3, 4, col)] + new Vector3(w2, h2, 0);
        vertices_new[ixy.i(6, 6, col)] = vertices_new[ixy.i(4, 4, col)] + new Vector3(w2, h2, 0);

        // ----- Side ----- //
        float W1 = have_water_right ? 0 : w1;
        float W2 = have_water_right ? 0 : w2;
        vertices_new[ixy.i(5, 0, col)] = vertices_new[ixy.i(4, 0, col)];
        vertices_new[ixy.i(6, 0, col)] = vertices_new[ixy.i(4, 0, col)];
        vertices_new[ixy.i(5, 1, col)] = vertices_new[ixy.i(4, 0, col)] + new Vector3(W1, h1, 0);
        vertices_new[ixy.i(6, 1, col)] = vertices_new[ixy.i(5, 1, col)];
        vertices_new[ixy.i(5, 2, col)] = vertices_new[ixy.i(4, 1, col)] + new Vector3(W1, h1, 0);
        vertices_new[ixy.i(6, 2, col)] = vertices_new[ixy.i(4, 0, col)] + new Vector3(W2, h2, 0);
        vertices_new[ixy.i(5, 3, col)] = vertices_new[ixy.i(4, 2, col)] + new Vector3(W1, h1, 0);
        vertices_new[ixy.i(6, 3, col)] = vertices_new[ixy.i(4, 2, col)] + new Vector3(W2, h2, 0);
        vertices_new[ixy.i(5, 4, col)] = vertices_new[ixy.i(4, 3, col)] + new Vector3(W1, h1, 0);
        vertices_new[ixy.i(6, 4, col)] = vertices_new[ixy.i(4, 3, col)] + new Vector3(W2, h2, 0);
        vertices_new[ixy.i(6, 5, col)] = vertices_new[ixy.i(4, 4, col)] + new Vector3(W2, h2, 0);




        // float x_, y_;
        // for (int x = 0; x < col; x++){
        //     for (int y = 0; y < row; y++){
        //         int i = ixy.i(x, y, col);
        //         Vector3 vertex = water.mesh.vertices[i];
        //         x_ = (float)x / (col - 1);
        //         // x_ = Mathf.Min(x_, 4.0f / 6.0f);
        //         y_ = (float)y / (row - 1);
        //         // y_ = Mathf.Min((float)y / (row - 1), heights[Mathf.Min(x, 4)]);
        //         if      (y == col - 1 && x >= 2)    y_ = Mathf.Min(y_, heights[Mathf.Min(x-2, 4)]);
        //         else if (y == col - 2 && x >= 1)    y_ = Mathf.Min(y_, heights[Mathf.Min(x-1, 4)]);
        //         // else if (x == row - 1 && y >= 2)    y_ = Mathf.Min(y_, heights[Mathf.Min(x-2, 4)]);
        //         // else if (x == row - 2 && y >= 1)    y_ = Mathf.Min(y_, heights[Mathf.Min(x-1, 4)]);
        //         else                                y_ = Mathf.Min(y_, heights[Mathf.Min(x, 4)]);
        //         y_ = Mathf.Min(y_, 4.0f / 6.0f);
        //         // if (y == 5) y_ += h5;
        //         // else if (y == 6) y_ += h6;
        //         if (x >= col_front || y >= row_front) {
        //             x_ += P3D_offset[x, y, 0];
        //             y_ += P3D_offset[x, y, 1];
        //         }
        //         vertex.x = x_ * P3D_scale; 
        //         vertex.y = y_ * P3D_scale;
        //         vertices_new[i] = vertex;
        //     }
        // }
        // for (int i = 0; i < vertices_new.Length; i++){
        //     vertices_new[i] *= P3D_scale;
        // }
        water.mesh.vertices = vertices_new;
        water.mesh.RecalculateNormals();
    }
}
