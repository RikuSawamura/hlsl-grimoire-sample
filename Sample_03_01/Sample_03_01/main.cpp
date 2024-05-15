#include "stdafx.h"
#include "system/system.h"
#include "TrianglePolygon.h"

//関数宣言
void InitRootSignature(RootSignature& rs);

///////////////////////////////////////////////////////////////////
// ウィンドウプログラムのメイン関数
///////////////////////////////////////////////////////////////////
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow)
{
	//ゲームの初期化
	InitGame(hInstance, hPrevInstance, lpCmdLine, nCmdShow, TEXT("Game"));

	//////////////////////////////////////
	// ここから初期化を行うコードを記述する
	//////////////////////////////////////

	//ルートシグネチャを作成
	RootSignature rootSignature;
	InitRootSignature(rootSignature);

	//三角形ポリゴンを定義
	TrianglePolygon triangle;
	triangle.Init(rootSignature);

	// step-1 定数バッファを作成
	ConstantBuffer cb;
	cb.Init(sizeof(Matrix));

	// step-2 ディスクリプタヒープを作成
	DescriptorHeap ds;
	//ディスクリプタヒープに定数バッファーを登録
	ds.RegistConstantBuffer(0, cb);
	//ディスクリプタヒープへの登録を確定
	ds.Commit();

	//////////////////////////////////////
	// 初期化を行うコードを書くのはここまで！！！
	//////////////////////////////////////
	auto& renderContext = g_graphicsEngine->GetRenderContext();

	float  f = 0.0f;
	// ここからゲームループ
	while (DispatchWindowMessage())
	{
		f++;
		//フレーム開始
		g_engine->BeginFrame();

		//////////////////////////////////////
		//ここから絵を描くコードを記述する
		//////////////////////////////////////

		//ルートシグネチャを設定
		renderContext.SetRootSignature(rootSignature);

		// step-3 ワールド行列を作成
		Matrix mWorld;
		
		//左に配置
		mWorld.MakeTranslation(-0.5f, 0.0f, 0.0f);

		//左右に往復
		//mWorld.MakeTranslation(0.5f * sin(f / 100.0f),0.0f,0.0f);

		//z軸回転
		//mWorld.MakeRotationZ(f / 90.0f);

		//z軸回転でアニメーション
		//Matrix mWorld1;
		//mWorld1.MakeTranslation(0.5 * sin( f / 100.0f),0.0f,0.0f);
		//Matrix mWorld2;
		//mWorld2.MakeRotationZ(f / 90.0f);
		//Matrix mWorld = mWorld2 * mWorld1;

		//円運動
		//mWorld.MakeTranslation(0.5f * sin(f/100.0f), 0.4f * cos(f / 100.0f), 0.0f);

		// step-4 ワールド行列をグラフィックメモリにコピー
		cb.CopyToVRAM(mWorld);

		// step-5 ディスクリプタヒープを設定
		renderContext.SetDescriptorHeap(ds);

		//三角形をドロー
		triangle.Draw(renderContext);

		/// //////////////////////////////////////
		//絵を描くコードを書くのはここまで！！！
		//////////////////////////////////////
		//フレーム終了
		g_engine->EndFrame();
	}
	return 0;
}

//ルートシグネチャの初期化
void InitRootSignature(RootSignature& rs)
{
	rs.Init(D3D12_FILTER_MIN_MAG_MIP_LINEAR,
		D3D12_TEXTURE_ADDRESS_MODE_WRAP,
		D3D12_TEXTURE_ADDRESS_MODE_WRAP,
		D3D12_TEXTURE_ADDRESS_MODE_WRAP);
}
