<?php

namespace App\Http\Controllers\API;

use App\Models\User;
use App\Models\Absensi;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;


class AndroidController extends Controller
{
    public function index()
    {
        $data = User::find(auth()->user()->id);

        return response()->json([
            'data' => $data,
            'message' => 'Data Success'
        ], 200);
    }

    public function getAbsensiToday()
    {
        $absensi = Absensi::where('user_id', auth()->user()->id)->whereDate('waktu_absen', date('Y-m-d'))->limit(2)->get();

        return response()->json([
            'data' => $absensi,
            'message' => 'Data Success'
        ], 200);
    }

    public function getAbsensiHistory()
    {
        $userId = auth()->user()->id;
        $startDate = now()->startOfWeek(); // Mulai dari hari Senin
        $endDate = $startDate->copy()->addDays(4); // Ambil 5 hari: Senin–Jumat

        // Ambil absensi dalam rentang Senin–Jumat
        $absensi = Absensi::where('user_id', $userId)
            ->whereBetween('waktu_absen', [
                $startDate->copy()->startOfDay(),
                $endDate->copy()->endOfDay()
            ])
            ->get()
            ->groupBy(function ($item) {
                return \Carbon\Carbon::parse($item->waktu_absen)->format('l');
            });

        // Buat struktur Senin–Jumat
        $result = [];
        for ($i = 0; $i < 5; $i++) {
            $date = now()->startOfWeek()->addDays($i);
            $dayName = $date->format('l');
            $result[$dayName] = [
                'tanggal' => $date->toDateString(),
                'absensi' => $absensi->get($dayName)?->take(2)->values() ?? [],
            ];
        }

        return response()->json([
            'data' => $result,
            'message' => 'Data Success'
        ], 200);
    }

    public function create(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'foto' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $data = $validator->validated();

        // $kantorLat = -6.881233;
        $kantorLat = 37.4219980;
        // $kantorLng = 107.587617;
        $kantorLng = -122.084;
        $radius = 40000; // meter

        $jarak = $this->hitungJarak($kantorLat, $kantorLng, $data['latitude'], $data['longitude']);

        if ($jarak > $radius) {
            return response()->json([
                'message' => 'Anda di luar jangkauan kantor',
                'jarak' => $jarak,
                'radius' => $radius,
            ], 403);
        }

        // Cek absensi hari ini
        $userId = auth()->user()->id;
        $today = now()->format('Y-m-d');
        $absensiToday = Absensi::where('user_id', $userId)
            ->whereDate('waktu_absen', $today)
            ->orderBy('waktu_absen')
            ->get();

        // Tentukan flag
        $flag = 1;
        if ($absensiToday->where('flag', 1)->count() > 0 && $absensiToday->where('flag', 2)->count() == 0) {
            $flag = 2;
        } elseif ($absensiToday->where('flag', 2)->count() > 0) {
            // Sudah absen keluar hari ini, bisa return error atau reset ke 1 jika diizinkan
            return response()->json([
                'message' => 'Sudah absen masuk dan keluar hari ini',
            ], 400);
        }

        // Simpan foto
        $imageName = 'absensi_' . time() . '.png';
        $image = base64_decode(str_replace(' ', '+', str_replace('data:image/png;base64,', '', $data['foto'])));
        Storage::disk('public')->put("absensi/{$imageName}", $image);

        $absensi = Absensi::create([
            'user_id' => $userId,
            'latitude' => $data['latitude'],
            'longitude' => $data['longitude'],
            'foto' => $imageName,
            'flag' => $flag,
            'waktu_absen' => now()->setTimezone('Asia/Jakarta')->format('Y-m-d H:i:s'),
        ]);

        return response()->json([
            'data' => $absensi,
            'message' => 'Absensi berhasil'
        ], 200);
    }

    private function hitungJarak($lat1, $lon1, $lat2, $lon2)
    {
        // Radius Bumi dalam Meter
        $earthRadius = 6371000;

        $latFrom = deg2rad($lat1);
        $lonFrom = deg2rad($lon1);
        $latTo = deg2rad($lat2);
        $lonTo = deg2rad($lon2);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));

        // Hasil dalam meter
        return $angle * $earthRadius;
    }
}