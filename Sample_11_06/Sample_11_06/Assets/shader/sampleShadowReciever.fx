/*!
 * @brief 影が落とされるモデル用のシェーダー
 */

 // モデル用の定数バッファー
cbuffer ModelCb : register(b0)
{
	float4x4 mWorld;
	float4x4 mView;
	float4x4 mProj;
};

// step-12 ライトビュープロジェクションクロップ行列の定数バッファーを定義
cbuffer ShadowParamCb:register(b1)
{
	float4x4 mLVPC[4];  // ライトビュープロジェクションクロップ行列
	// 3→4に変更
};

// 頂点シェーダーへの入力
struct SVSIn
{
	float4 pos : POSITION;  // スクリーン空間でのピクセルの座標
	float3 normal : NORMAL; // 法線
	float2 uv : TEXCOORD0;  // uv座標
};

// ピクセルシェーダーへの入力
struct SPSIn
{
	float4 pos : SV_POSITION;   // スクリーン空間でのピクセルの座標
	float3 normal : NORMAL;     // 法線
	float2 uv : TEXCOORD0;      // uv座標

	// step-13 ライトビュースクリーン空間での座標を追加
	float4 posInLVP[4]:TEXCOORD1;  // ライトビュースクリーン空間でのピクセルの座標
	// 3→4に変更
};

///////////////////////////////////////////////////
// グローバル変数
///////////////////////////////////////////////////

Texture2D<float4> g_albedo : register(t0); // アルベドマップ

// step-14 近～中距離のシャドウマップにアクセスするための変数を定義
Texture2D<float4>g_shadowMap_0:register(t10);   // 近距離のシャドウマップ
Texture2D<float4>g_shadowMap_1:register(t11);   // 中距離のシャドウマップ
Texture2D<float4>g_shadowMap_2:register(t12);   // 遠距離のシャドウマップ
// 4段階目
Texture2D<float4>g_shadowMap_3:register(t13);	// 追加分


sampler g_sampler : register(s0); //  サンプラーステート

/// <summary>
/// 影が落とされる3Dモデル用の頂点シェーダー
/// </summary>
SPSIn VSMain(SVSIn vsIn)
{
	// 通常の座標変換
	SPSIn psIn;
	float4 worldPos = mul(mWorld, vsIn.pos);
	psIn.pos = mul(mView, worldPos);
	psIn.pos = mul(mProj, psIn.pos);
	psIn.uv = vsIn.uv;
	psIn.normal = mul(mWorld, vsIn.normal);

	// step-15 ライトビュースクリーン空間の座標を計算する
	psIn.posInLVP[0] = mul(mLVPC[0], worldPos);
	psIn.posInLVP[1] = mul(mLVPC[1], worldPos);
	psIn.posInLVP[2] = mul(mLVPC[2], worldPos);
	// 4段階目
	psIn.posInLVP[3] = mul(mLVPC[3], worldPos);	// 追加分

	return psIn;
}

/// <summary>
/// 影が落とされる3Dモデル用のピクセルシェーダー
/// </summary>
float4 PSMain(SPSIn psIn) : SV_Target0
{
	float4 color = g_albedo.Sample(g_sampler, psIn.uv);
	Texture2D<float4> shadowMapArray[4];	// 3→4に変更
	shadowMapArray[0] = g_shadowMap_0;
	shadowMapArray[1] = g_shadowMap_1;
	shadowMapArray[2] = g_shadowMap_2;
	// 4段階目
	shadowMapArray[3] = g_shadowMap_3;	// 追加分

	// step-16 3枚のシャドウマップを使って、シャドウレシーバーに影を落とす
	for (int cascadeIndex = 0; cascadeIndex < 4; cascadeIndex++)	// 3→4に変更
	{
		// ライトビュースクリーン空間でのZ値を計算する
		float zInLVP = psIn.posInLVP[cascadeIndex].z / psIn.posInLVP[cascadeIndex].w;
		if (zInLVP >= 0.0f && zInLVP <= 1.0f)
		{
			// Zの値を見て、このピクセルがこのシャドウマップに含まれているか判定
			float2 shadowMapUV = psIn.posInLVP[cascadeIndex].xy
				/ psIn.posInLVP[cascadeIndex].w;
			shadowMapUV *= float2(0.5f, -0.5f);
			shadowMapUV += 0.5f;

			// シャドウマップUVが範囲内か判定
			if (shadowMapUV.x >= 0.0f && shadowMapUV.x <= 1.0f
				&& shadowMapUV.y >= 0.0f && shadowMapUV.y <= 1.0f)
			{
				// シャドウマップから値をサンプリング
				float2 shadowValue = shadowMapArray[cascadeIndex].Sample(
					g_sampler,shadowMapUV).xy;

				// まずこのピクセルが遮蔽されているか調べる
				if (zInLVP >= shadowValue.r)
				{
					color.xyz *= 0.5f;

					// 影を落とせたので終了
					break;
				}
			}
		}
	}

	return color;
}
