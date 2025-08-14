<?php

namespace App\Http\Controllers\API;

use DB;
use Exception;
use Carbon\Carbon;
use App\Models\Izin;
use App\Models\User;
use App\Models\Jabatan;
use App\Models\Karyawan;
use App\Models\StatusHadir;
use Illuminate\Support\Str;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Response;

class IzinController extends Controller
{
    public function index()
    {
        $izin = Izin::select('hr_cuti.*', 'karyawan.nama as nama_karyawan', 'hr_status_hadir.nama as nama_status_hadir')
            ->leftJoin('karyawan', 'hr_cuti.karyawan_id', '=', 'karyawan.id')
            ->leftJoin('hr_status_hadir', 'hr_cuti.status_hadir_id', '=', 'hr_status_hadir.id')
            ->where('hr_cuti.karyawan_id', auth()->user()->karyawan_id)
            ->orderBy('hr_cuti.id', 'desc')
            ->get()
            ->map(function ($item) {
                $tanggalAwal = Carbon::parse($item->tanggal_awal);
                $tanggalAkhir = Carbon::parse($item->tanggal_akhir);

                $item->jumlah_hari = $tanggalAwal->diffInDays($tanggalAkhir) + 1;

                return $item;
            });

        return response()->json([
            'data' => $izin,
            'message' => 'Data Success'
        ], 200);
    }

    public function create(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'tanggal_awal' => 'required|date',
            'tanggal_akhir' => 'required|date',
            'status_hadir_id' => 'required',
            'dokumen' => 'nullable|file|mimes:jpeg,png,jpg,pdf,doc,docx|max:2048',
            'keterangan' => 'nullable|string',
        ]);

        $imageName = null;

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }
        $data = $validator->validated();

        // Simpan dokumen
        if ($request->hasFile('dokumen')) {
            $imageName = 'izin_' . time() . '.' . $request->file('dokumen')->getClientOriginalExtension();

            $uploadPath = public_path('uploads/izin');
            if (!file_exists($uploadPath)) {
                mkdir($uploadPath, 0755, true);
            }

            $request->file('dokumen')->move($uploadPath, $imageName);
        }

        $tanggalAwal = Carbon::parse($data['tanggal_awal']);
        $tanggalAkhir = Carbon::parse($data['tanggal_akhir']);
        $jumlahCuti = $tanggalAwal->diffInDays($tanggalAkhir) + 1;

        $izin = Izin::create([
            'karyawan_id' => auth()->user()->karyawan_id,
            'status_hadir_id' => $data['status_hadir_id'],
            'tanggal_awal' => date('Y-m-d', strtotime($data['tanggal_awal'])),
            'tanggal_akhir' => date('Y-m-d', strtotime($data['tanggal_akhir'])),
            'jumlah_cuti' => $jumlahCuti,
            'keterangan' => $data['keterangan'],
            'dokumen' => $imageName,
        ]);

        return response()->json([
            'data' => $izin,
            'message' => 'Izin berhasil'
        ], 200);
    }

    public function show($id)
    {
        try {
            $izin = Izin::select('hr_cuti.*', 'hr_status_hadir.nama as nama_status_hadir', 'hr_users.nama as name_user_acc')
                ->leftJoin('hr_status_hadir', 'hr_cuti.status_hadir_id', '=', 'hr_status_hadir.id')
                ->leftJoin('hr_users', 'hr_users.id', '=', 'hr_cuti.personalia_id')
                ->where('hr_cuti.id', $id)
                ->first();

            return response()->json([
                'data' => $izin,
                'message' => 'Data Success'
            ], 200);
        } catch (Exception $e) {

            return response()->json([
                'message' => 'Izin tidak ditemukan'
            ], 404);
        }
    }

    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'tanggal_awal' => 'required|date',
            'tanggal_akhir' => 'required|date',
            'status_hadir_id' => 'required',
            'dokumen' => 'nullable',
            'keterangan' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        DB::beginTransaction();
        try {

            $tanggalAwal = Carbon::parse($request->tanggal_awal);
            $tanggalAkhir = Carbon::parse($request->tanggal_akhir);
            $jumlahCuti = $tanggalAwal->diffInDays($tanggalAkhir) + 1;

            $izin = Izin::findOrFail($id);
            $izin->tanggal_awal = date('Y-m-d', strtotime($request->tanggal_awal));
            $izin->tanggal_akhir = date('Y-m-d', strtotime($request->tanggal_akhir));
            $izin->status_hadir_id = $request->status_hadir_id;
            $izin->keterangan = $request->keterangan;
            $izin->jumlah_cuti = $jumlahCuti;
            if ($request->hasFile('dokumen')) {
                $imageName = 'izin_' . time() . '.' . $request->file('dokumen')->getClientOriginalExtension();

                $uploadPath = public_path('uploads/izin');
                if (!file_exists($uploadPath)) {
                    mkdir($uploadPath, 0755, true);
                }

                $request->file('dokumen')->move($uploadPath, $imageName);
                $izin->dokumen = $imageName;
            }
            $izin->save();
        } catch (Exception $e) {
            DB::rollback();
            return response()->json(['warning' => 'Error : ' . $e->getMessage()], 500);
        }

        DB::commit();

        return response()->json([
            'data' => $izin,
            'message' => 'Update Success'
        ], 200);
    }

    public function delete($id)
    {
        $izin = Izin::findOrFail($id);
        $izin->delete();

        return response()->json([
            'data' => $izin,
            'message' => 'Delete Success'
        ], 200);
    }

    public function getDataStatusHadir()
    {
        $statusHadir = StatusHadir::all();

        return response()->json([
            'data' => $statusHadir,
            'message' => 'Data Success'
        ], 200);
    }

    public function getSisaCuti()
    {
        // $sisaCuti = Izin::select('hr_cuti.*')
        //     ->leftJoin('hr_status_hadir', 'hr_cuti.status_hadir_id', '=', 'hr_status_hadir.id')
        //     ->where('hr_status_hadir.kode', 'IC')
        //     ->where('karyawan_id', auth()->user()->karyawan_id)
        //     ->where('validasi_personalia', true)
        //     ->where('keterangan_tolak_personalia', null)
        //     ->sum('jumlah_cuti');

        // $jatahCuti = 12;

        // $data = $jatahCuti - $sisaCuti;

        $tanggalMasuk = Karyawan::where('id', auth()->user()->karyawan_id)->value('tanggal_masuk');
        $tanggalMasuk = Carbon::parse($tanggalMasuk);
        $today = Carbon::today();

        $startOfPeriod = $tanggalMasuk->copy()->year($today->year);
        if ($today->lt($startOfPeriod)) {
            $startOfPeriod->subYear();
        }
        $endOfPeriod = $startOfPeriod->copy()->addYear()->subDay();

        $sisaCuti = Izin::select('hr_cuti.*')
            ->leftJoin('hr_status_hadir', 'hr_cuti.status_hadir_id', '=', 'hr_status_hadir.id')
            ->where('hr_status_hadir.kode', 'IC')
            ->where('karyawan_id', auth()->user()->karyawan_id)
            ->where('validasi_personalia', true)
            ->where('keterangan_tolak_personalia', null)
            ->whereBetween('tanggal_awal', [$startOfPeriod, $endOfPeriod])
            ->sum('jumlah_cuti');

        $jatahCuti = Jabatan::leftJoin('karyawan', 'karyawan.jabatan_id', '=', 'jabatan.id')
            ->where('karyawan.id', auth()->user()->karyawan_id)
            ->value('jatah_cuti') ?? 12;

        $sisaCutiAkhir = $jatahCuti - $sisaCuti;

        return response()->json([
            'data' => $sisaCutiAkhir,
            'message' => 'Data Success'
        ], 200);
    }

    public function getSisaCutiDetail($id)
    {
        // $tanggalMasuk = Karyawan::select('tanggal_masuk')
        //     ->where('id', $id)
        //     ->first();

        // $sisaCuti = Izin::select('hr_cuti.*')
        //     ->leftJoin('hr_status_hadir', 'hr_cuti.status_hadir_id', '=', 'hr_status_hadir.id')
        //     ->where('hr_status_hadir.kode', 'IC')
        //     ->where('karyawan_id', $id)
        //     ->where('validasi_personalia', true)
        //     ->where('keterangan_tolak_personalia', null)
        //     ->sum('jumlah_cuti');

        // $jatahCuti = Jabatan::select('jabatan.jatah_cuti')
        //     ->leftJoin('karyawan', 'karyawan.jabatan_id', '=', 'jabatan.id')
        //     ->where('karyawan.id', $id)
        //     ->first();

        // if($jatahCuti->jatah_cuti){
        //     $jatahCuti = $jatahCuti->jatah_cuti;
        // }else{
        //     $jatahCuti = 12;
        // }

        // $data = $jatahCuti - $sisaCuti;

        $tanggalMasuk = Karyawan::where('id', $id)->value('tanggal_masuk');
        $tanggalMasuk = Carbon::parse($tanggalMasuk);
        $today = Carbon::today();

        $startOfPeriod = $tanggalMasuk->copy()->year($today->year);
        if ($today->lt($startOfPeriod)) {
            $startOfPeriod->subYear();
        }
        $endOfPeriod = $startOfPeriod->copy()->addYear()->subDay();

        $sisaCuti = Izin::select('hr_cuti.*')
            ->leftJoin('hr_status_hadir', 'hr_cuti.status_hadir_id', '=', 'hr_status_hadir.id')
            ->where('hr_status_hadir.kode', 'IC')
            ->where('karyawan_id', $id)
            ->where('validasi_personalia', true)
            ->where('keterangan_tolak_personalia', null)
            ->whereBetween('tanggal_awal', [$startOfPeriod, $endOfPeriod])
            ->sum('jumlah_cuti');

        $jatahCuti = Jabatan::leftJoin('karyawan', 'karyawan.jabatan_id', '=', 'jabatan.id')
            ->where('karyawan.id', $id)
            ->value('jatah_cuti') ?? 12;

        $sisaCutiAkhir = $jatahCuti - $sisaCuti;

        return response()->json([
            'data' => $sisaCutiAkhir,
            'message' => 'Data Success'
        ], 200);
    }

    public function approve($id)
    {
        $izin = Izin::findOrFail($id);
        $izin->personalia_id = auth()->user()->id;
        $izin->validasi_personalia = true;
        $izin->tanggal_approve = now()->format('Y-m-d H:i:s');
        $izin->save();

        return response()->json([
            'data' => $izin,
            'message' => 'Approve Success'
        ], 200);
    }

    public function reject($id, Request $request)
    {
        $izin = Izin::findOrFail($id);
        $izin->personalia_id = auth()->user()->id;
        $izin->validasi_personalia = false;
        $izin->keterangan_tolak_personalia = $request->keterangan;
        $izin->tanggal_reject = now()->format('Y-m-d H:i:s');
        $izin->save();

        return response()->json([
            'data' => $izin,
            'message' => 'Reject Success'
        ], 200);
    }

    public function generateNotificationToken($id)
    {
        try {
            $izin = Izin::findOrFail($id);

            // Ambil semua user HRD
            $usersHrd = User::select('hr_users.*')
                ->leftJoin('hr_user_groups', 'hr_user_groups.id', '=', 'hr_users.user_group_id')
                ->where('hr_user_groups.kode', 'HRD')
                ->get();

            $tokens = [];

            // Generate token untuk setiap user HRD
            foreach ($usersHrd as $userHrd) {
                $token = Str::random(64);

                Cache::put("notification_token_{$token}", [
                    'izin_id' => $id,
                    'user_id' => $userHrd->id,
                    'created_at' => now()
                ], now()->addHours(24));

                $tokens[] = [
                    'token' => $token,
                    'user_id' => $userHrd->id,
                    'user_name' => $userHrd->name ?? $userHrd->username ?? 'HRD User'
                ];
            }

            return response()->json([
                'data' => [
                    'tokens' => $tokens,
                    'izin_id' => $id,
                    'total_hrd_users' => count($usersHrd)
                ],
                'message' => 'Tokens generated successfully for all HRD users'
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error generating tokens: ' . $e->getMessage()
            ], 500);
        }
    }

    public function hashUserId($userId)
    {
        $data = $userId . '|' . time();
        $hash = base64_encode($data);

        $hash = str_replace(['+', '/', '='], ['-', '_', ''], $hash);

        return response()->json([
            'data' => $hash,
            'message' => 'Hash generated successfully'
        ], 200);
    }

    public function decodeUserId($hash)
    {
        try {
            $hash = str_replace(['-', '_'], ['+', '/'], $hash);

            $hash = str_pad($hash, strlen($hash) % 4, '=', STR_PAD_RIGHT);

            $decoded = base64_decode($hash);

            $parts = explode('|', $decoded);
            if (count($parts) === 2) {
                $userId = $parts[0];
                $timestamp = $parts[1];

                // Cek apakah timestamp masih valid (24 jam)
                if (time() - $timestamp <= 86400) {
                    // Cek apakah user_id adalah user HRD yang valid
                    $userHrd = User::select('hr_users.id')
                        ->leftJoin('hr_user_groups', 'hr_user_groups.id', '=', 'hr_users.user_group_id')
                        ->where('hr_user_groups.kode', 'HRD')
                        ->where('hr_users.id', $userId)
                        ->first();

                    if ($userHrd) {
                        return $userId;
                    }
                }
            }

            return null;
        } catch (Exception $e) {
            return null;
        }
    }

    public function verifyNotificationToken(Request $request)
    {
        try {
            $token = $request->token;

            if (!$token) {
                return response()->json([
                    'message' => 'Token is required'
                ], 400);
            }

            $tokenData = Cache::get("notification_token_{$token}");

            if (!$tokenData) {
                return response()->json([
                    'message' => 'Invalid or expired token'
                ], 401);
            }

            $izin = Izin::select('hr_cuti.*', 'hr_status_hadir.nama as nama_status_hadir')
                ->leftJoin('hr_status_hadir', 'hr_cuti.status_hadir_id', '=', 'hr_status_hadir.id')
                ->where('hr_cuti.id', $tokenData['izin_id'])
                ->first();

            if (!$izin) {
                return response()->json([
                    'message' => 'Izin not found'
                ], 404);
            }

            $user = User::find($tokenData['user_id']);
            if (!$user) {
                return response()->json([
                    'message' => 'User not found'
                ], 404);
            }

            $accessToken = $user->createToken('notification_token')->plainTextToken;

            return response()->json([
                'data' => [
                    'izin' => $izin,
                    'access_token' => $accessToken,
                    'token_type' => 'Bearer'
                ],
                'message' => 'Token verified successfully'
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'message' => 'Error verifying token: ' . $e->getMessage()
            ], 500);
        }
    }

    public function autoLoginFromNotification(Request $request)
    {
        try {
            $izinId = $request->izin_id;
            $userHash = $request->user_hash;

            Log::info('Auto login attempt', [
                'izin_id' => $izinId,
                'user_hash' => $userHash
            ]);

            if (!$izinId) {
                return response()->json([
                    'message' => 'Izin ID is required'
                ], 400);
            }

            // Ambil semua user HRD
            $usersHrd = User::select('hr_users.*')
                ->leftJoin('hr_user_groups', 'hr_user_groups.id', '=', 'hr_users.user_group_id')
                ->where('hr_user_groups.kode', 'HRD')
                ->get();

            Log::info('HRD users found', ['count' => $usersHrd->count()]);

            if ($usersHrd->isEmpty()) {
                return response()->json([
                    'message' => 'No HRD users found'
                ], 404);
            }

            // Jika ada user_hash, decode untuk mendapatkan user_id
            if ($userHash) {
                $userId = $this->decodeUserId($userHash);
                Log::info('Decoded user_id', ['user_id' => $userId]);

                if ($userId) {
                    $userHrd = $usersHrd->where('id', $userId)->first();
                    if (!$userHrd) {
                        return response()->json([
                            'message' => 'User HRD not found'
                        ], 404);
                    }
                } else {
                    // Fallback ke user HRD pertama jika hash tidak valid
                    $userHrd = $usersHrd->first();
                    Log::warning('Invalid user hash, using first HRD user', ['user_id' => $userHrd->id]);
                }
            } else {
                // Jika tidak ada user_hash, ambil user HRD pertama sebagai default
                $userHrd = $usersHrd->first();
                Log::info('No user hash, using first HRD user', ['user_id' => $userHrd->id]);
            }

            $izin = Izin::select('hr_cuti.*', 'hr_status_hadir.nama as nama_status_hadir')
                ->leftJoin('hr_status_hadir', 'hr_cuti.status_hadir_id', '=', 'hr_status_hadir.id')
                ->where('hr_cuti.id', $izinId)
                ->first();

            if (!$izin) {
                return response()->json([
                    'message' => 'Izin not found'
                ], 404);
            }

            $accessToken = $userHrd->createToken('notification_token')->plainTextToken;

            Log::info('Auto login successful', [
                'user_id' => $userHrd->id,
                'izin_id' => $izinId
            ]);

            return response()->json([
                'data' => [
                    'izin' => $izin,
                    'access_token' => $accessToken,
                    'token_type' => 'Bearer',
                    'user' => $userHrd
                ],
                'message' => 'Auto login successful'
            ], 200);
        } catch (Exception $e) {
            Log::error('Auto login error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'message' => 'Error auto login: ' . $e->getMessage()
            ], 500);
        }
    }

    public function getUserHrd()
    {
        $userHrd = User::select('hr_users.*', 'karyawan.no_telepon')
            ->leftJoin('karyawan', 'karyawan.id', '=', 'hr_users.karyawan_id')
            ->leftJoin('hr_user_groups', 'hr_user_groups.id', '=', 'hr_users.user_group_id')
            ->where('hr_user_groups.kode', 'HRD')
            ->get();

        return response()->json([
            'data' => $userHrd,
            'message' => 'Data Success'
        ], 200);
    }

    public function getUserHrdAcc()
    {
        $userHrd = User::select('hr_users.*', 'karyawan.no_telepon')
            ->leftJoin('karyawan', 'karyawan.id', '=', 'hr_users.karyawan_id')
            ->leftJoin('hr_user_groups', 'hr_user_groups.id', '=', 'hr_users.user_group_id')
            ->where('hr_user_groups.kode', 'HRD')
            ->where('hr_users.id', auth()->user()->id)
            ->first();

        return response()->json([
            'data' => $userHrd,
            'message' => 'Data Success'
        ], 200);
    }
}
