// using System.Collections.Generic;
// using UnityEngine;

// public class FindNearest{
//     public bool[,] generatedBlocks; // 表示是否已经生成的块
//     public Vector2Int gridSize; // 表示整个网格的大小，例如 (width, height)
//     public Vector2Int startPoint; // 起始坐标点
//     public Vector2Int[] directions = {
//         new Vector2Int(1, 0),  // 右
//         new Vector2Int(-1, 0), // 左
//         new Vector2Int(0, 1),  // 上
//         new Vector2Int(0, -1)  // 下
//     };

//     public Vector2Int _find_nearest_point(Vector2Int start_point, ){
//         Queue<Vector2Int> queue = new Queue<Vector2Int>();
//         HashSet<Vector2Int> visited = new HashSet<Vector2Int>();

//         queue.Enqueue(start_point);
//         visited.Add(start_point);

//         while (queue.Count > 0){
//             Vector2Int current = queue.Dequeue();

//             // 检查当前块是否未生成
//             if (!generatedBlocks[current.x, current.y])
//             {
//                 return current; // 找到最近未生成的块
//             }

//             // 遍历四个方向
//             foreach (Vector2Int direction in directions)
//             {
//                 Vector2Int next = current + direction;

//                 // 确保坐标在网格范围内，并且没有被访问过
//                 if (IsWithinBounds(next) && !visited.Contains(next))
//                 {
//                     queue.Enqueue(next);
//                     visited.Add(next);
//                 }
//             }
//         }

//         // 如果没有找到未生成的块，返回一个无效值
//         return new Vector2Int(-1, -1);
//     }

//     // 判断坐标是否在网格范围内
//     private bool IsWithinBounds(Vector2Int point){
//         return point.x >= 0 && point.x < gridSize.x && point.y >= 0 && point.y < gridSize.y;
//     }

//     void Start(){
//         // 示例初始化
//         gridSize = new Vector2Int(10, 10); // 假设网格大小是10x10
//         generatedBlocks = new bool[gridSize.x, gridSize.y];
        
//         // 初始化一些块为已生成，其他块未生成
//         for (int x = 0; x < gridSize.x; x++)
//         {
//             for (int y = 0; y < gridSize.y; y++)
//             {
//                 generatedBlocks[x, y] = Random.value > 0.5f; // 随机设定部分块为生成状态
//             }
//         }

//         // 设置起点
//         startPoint = new Vector2Int(5, 5);

//         // 查找最近的未生成块
//         Vector2Int nearestBlock = FindNearestUnspawnedBlock(startPoint);
//         if (nearestBlock != new Vector2Int(-1, -1)){
//             Debug.Log("最近的未生成块位置: " + nearestBlock);
//         }
//         else{
//             Debug.Log("没有找到未生成的块");
//         }
//     }
// }
