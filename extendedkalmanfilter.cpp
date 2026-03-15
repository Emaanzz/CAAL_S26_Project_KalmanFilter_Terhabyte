#include <iostream>
#include <vector>
#include <cmath>
#include <fstream>
#include <sstream>
#include <string>
#include <stdexcept>

#ifdef _WIN32
#include <windows.h>
#endif

// AUTO FILE FINDER
std::string findCSV() {
    std::vector<std::string> candidates = {
        "C:\\Users\\Admin\\Desktop\\3D Full Body Humain Gait Walking Dataset (Noisy Values).csv",
        "C:\\Users\\Admin\\Downloads\\3D Full Body Humain Gait Walking Dataset (Noisy Values).csv",
        "C:\\Users\\Admin\\Documents\\3D Full Body Humain Gait Walking Dataset (Noisy Values).csv",
        "C:\\Users\\Admin\\OneDrive\\Desktop\\3D Full Body Humain Gait Walking Dataset (Noisy Values).csv",
        "C:\\Users\\Admin\\OneDrive - Institute of Business Administration\\Desktop\\3D Full Body Humain Gait Walking Dataset (Noisy Values).csv",
        "C:\\Users\\Admin\\OneDrive - Institute of Business Administration\\Desktop\\CAALProject\\3D Full Body Humain Gait Walking Dataset (Noisy Values).csv",
        "C:\\Users\\Admin\\OneDrive - Institute of Business Administration\\Desktop\\CAALProject\\SecondMilestone\\3D Full Body Humain Gait Walking Dataset (Noisy Values).csv",
        "3D Full Body Humain Gait Walking Dataset (Noisy Values).csv",
        "C:\\Users\\Admin\\Desktop\\3D Full Body Human Gait Walking Dataset (Noisy Values).csv",
        "C:\\Users\\Admin\\Downloads\\3D Full Body Human Gait Walking Dataset (Noisy Values).csv",
    };
    for (const auto& path : candidates) {
        std::ifstream f(path);
        if (f.is_open()) { f.close(); return path; }
    }
    return "";
}

// MATRIX CLASS 
class Matrix {
public:
    int rows, cols;
    std::vector<double> data;

    Matrix() : rows(0), cols(0) {}
    Matrix(int r, int c, double init_val = 0.0)
        : rows(r), cols(c), data(r * c, init_val) {}

    inline double& operator()(int r, int c)      { return data[r * cols + c]; }
    inline double  operator()(int r, int c) const { return data[r * cols + c]; }

    Matrix operator*(const Matrix& B) const {
        if (cols != B.rows) throw std::runtime_error("Dimension mismatch");
        Matrix C(rows, B.cols, 0.0);
        for (int i = 0; i < rows; ++i)
            for (int k = 0; k < cols; ++k) {
                double aik = (*this)(i, k);
                if (aik == 0.0) continue;
                for (int j = 0; j < B.cols; ++j)
                    C(i, j) += aik * B(k, j);
            }
        return C;
    }
    Matrix transpose() const {
        Matrix T(cols, rows);
        for (int i = 0; i < rows; ++i)
            for (int j = 0; j < cols; ++j)
                T(j, i) = (*this)(i, j);
        return T;
    }
    Matrix operator+(const Matrix& B) const {
        Matrix C(rows, cols);
        for (size_t i = 0; i < data.size(); ++i) C.data[i] = data[i] + B.data[i];
        return C;
    }
    Matrix operator-(const Matrix& B) const {
        Matrix C(rows, cols);
        for (size_t i = 0; i < data.size(); ++i) C.data[i] = data[i] - B.data[i];
        return C;
    }
    Matrix operator*(double s) const {
        Matrix C(rows, cols);
        for (size_t i = 0; i < data.size(); ++i) C.data[i] = data[i] * s;
        return C;
    }
};

static Matrix eye(int n) {
    Matrix I(n, n, 0.0);
    for (int i = 0; i < n; ++i) I(i, i) = 1.0;
    return I;
}

 
// SYMMETRY ENFORCEMENT — keeps P numerically symmetric
static void enforce_symmetry(Matrix& P) {
    for (int i = 0; i < P.rows; ++i)
        for (int j = i + 1; j < P.cols; ++j) {
            double avg = 0.5 * (P(i, j) + P(j, i));
            P(i, j) = avg; P(j, i) = avg;
        }
}

// CHOLESKY SOLVER 
static Matrix solveCholesky(const Matrix& A, const Matrix& B) {
    int n = A.rows;
    Matrix L(n, n, 0.0);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j <= i; j++) {
            double sum = 0.0;
            if (j == i) {
                for (int k = 0; k < j; k++) sum += L(j, k) * L(j, k);
                double val = A(j, j) - sum;
                L(j, j) = (val > 1e-12) ? std::sqrt(val) : 1e-9;
            } else {
                for (int k = 0; k < j; k++) sum += L(i, k) * L(j, k);
                L(i, j) = (A(i, j) - sum) / L(j, j);
            }
        }
    }
    Matrix X(B.rows, B.cols, 0.0);
    for (int c = 0; c < B.cols; c++) {
        std::vector<double> y(n, 0.0);
        for (int i = 0; i < n; i++) {
            double sum = 0.0;
            for (int k = 0; k < i; k++) sum += L(i, k) * y[k];
            y[i] = (B(i, c) - sum) / L(i, i);
        }
        for (int i = n - 1; i >= 0; i--) {
            double sum = 0.0;
            for (int k = i + 1; k < n; k++) sum += L(k, i) * X(k, c);
            X(i, c) = (y[i] - sum) / L(i, i);
        }
    }
    return X;
}

// MANUAL ARCTAN2 
static double manual_arctan2(double y, double x) {
    const double PI = 3.14159265358979323846;
    if (x == 0.0) {
        if (y > 0.0) return  PI / 2.0;
        if (y < 0.0) return -PI / 2.0;
        return 0.0;
    }
    double z = y / x;
    double abs_z = (z < 0.0) ? -z : z;
    double theta;
    if (abs_z <= 1.0) {
        theta = z / (1.0 + 0.28125 * abs_z * abs_z);
    } else {
        double inv_z = 1.0 / z;
        double abs_inv_z = (inv_z < 0.0) ? -inv_z : inv_z;
        double atan_inv = inv_z / (1.0 + 0.28125 * abs_inv_z * abs_inv_z);
        theta = (z > 0.0) ? (PI / 2.0 - atan_inv) : (-PI / 2.0 - atan_inv);
    }
    if (x < 0.0) theta += (y >= 0.0) ? PI : -PI;
    return theta;
}

static double wrap_angle(double a) {
    const double PI  = 3.14159265358979323846;
    const double TPI = 2.0 * PI;
    while (a >  PI) a -= TPI;
    while (a < -PI) a += TPI;
    return a;
}

// SYSTEM CONSTANTS
const int NUM_JOINTS       = 23;
const int STATES_PER_JOINT = 12;
const int TOTAL_STATES     = NUM_JOINTS * STATES_PER_JOINT;  // 276
const int MEAS_DIM         = NUM_JOINTS * 3;                  // 69

const std::string BONE_NAMES[23] = {
    "Pelvis","L5","L3","T12","T8","Neck","Head",
    "RightShoulder","RightUpperArm","RightForearm","RightHand",
    "LeftShoulder","LeftUpperArm","LeftForearm","LeftHand",
    "RightUpperLeg","RightLowerLeg","RightFoot","RightToe",
    "LeftUpperLeg","LeftLowerLeg","LeftFoot","LeftToe"
};

// VIRTUAL SENSOR POSITION

const double SENSOR_OX = -7.0;
const double SENSOR_OY = -8.0;
const double SENSOR_OZ =  0.0;

// BUILD F 
static Matrix build_F(double dt) {
    Matrix F(TOTAL_STATES, TOTAL_STATES, 0.0);
    const double dt2 = dt * dt, dt3 = dt2 * dt;
    for (int i = 0; i < NUM_JOINTS; ++i)
        for (int axis = 0; axis < 3; ++axis) {
            int b = i * 12 + axis * 4;
            F(b,   b)   = 1.0;  F(b,   b+1) = dt;      F(b,   b+2) = dt2/2.0; F(b,   b+3) = dt3/6.0;
            F(b+1, b+1) = 1.0;  F(b+1, b+2) = dt;      F(b+1, b+3) = dt2/2.0;
            F(b+2, b+2) = 1.0;  F(b+2, b+3) = dt;
            F(b+3, b+3) = 1.0;
        }
    return F;
}

// BUILD Q 
static Matrix build_Q(double dt, double sigma_j_sq) {
    Matrix Q(TOTAL_STATES, TOTAL_STATES, 0.0);
    const double dt2=dt*dt, dt3=dt2*dt, dt4=dt3*dt, dt5=dt4*dt, dt6=dt5*dt;
    const double q[4][4] = {
        {dt6/36.0, dt5/12.0, dt4/6.0, dt3/6.0},
        {dt5/12.0, dt4/4.0,  dt3/2.0, dt2/2.0},
        {dt4/6.0,  dt3/2.0,  dt2,     dt     },
        {dt3/6.0,  dt2/2.0,  dt,      1.0    }
    };
    for (int i = 0; i < NUM_JOINTS; ++i)
        for (int axis = 0; axis < 3; ++axis) {
            int b = i * 12 + axis * 4;
            for (int r = 0; r < 4; ++r)
                for (int c = 0; c < 4; ++c)
                    Q(b+r, b+c) = sigma_j_sq * q[r][c];
        }
    return Q;
}

static Matrix build_R(double sr, double s_az, double s_el) {
    Matrix R(MEAS_DIM, MEAS_DIM, 0.0);
    for (int i = 0; i < NUM_JOINTS; ++i) {
        R(i*3,   i*3)   = sr;
        R(i*3+1, i*3+1) = s_az;
        R(i*3+2, i*3+2) = s_el;
    }
    return R;
}

// h(x): Nonlinear measurement function
static Matrix compute_hx(const Matrix& X) {
    const double EPS = 1e-9;
    Matrix Z(MEAS_DIM, 1, 0.0);
    for (int i = 0; i < NUM_JOINTS; ++i) {
        double px = X(i*12,   0) - SENSOR_OX;
        double py = X(i*12+4, 0) - SENSOR_OY;
        double pz = X(i*12+8, 0) - SENSOR_OZ;
        double rho = std::sqrt(px*px + py*py + EPS);
        double r   = std::sqrt(px*px + py*py + pz*pz + EPS);
        Z(i*3,   0) = r;
        Z(i*3+1, 0) = manual_arctan2(py, px);
        Z(i*3+2, 0) = manual_arctan2(pz, rho);
    }
    return Z;
}

// Jacobian ∂h/∂x 
static Matrix compute_Jacobian(const Matrix& X) {
    const double EPS = 1e-9;
    Matrix Hj(MEAS_DIM, TOTAL_STATES, 0.0);
    for (int i = 0; i < NUM_JOINTS; ++i) {
        int s = i*12, z = i*3;
        double px = X(s,   0) - SENSOR_OX;
        double py = X(s+4, 0) - SENSOR_OY;
        double pz = X(s+8, 0) - SENSOR_OZ;
        double r2   = px*px + py*py + pz*pz + EPS;  double r   = std::sqrt(r2);
        double rho2 = px*px + py*py + EPS;           double rho = std::sqrt(rho2);

        // ∂r / ∂(px,py,pz)
        Hj(z,   s)   = px / r;
        Hj(z,   s+4) = py / r;
        Hj(z,   s+8) = pz / r;

        // ∂θ / ∂(px,py) — ∂θ/∂pz = 0
        Hj(z+1, s)   = -py / rho2;
        Hj(z+1, s+4) =  px / rho2;

        // ∂φ / ∂(px,py,pz)
        Hj(z+2, s)   = -(px * pz) / (r2 * rho);
        Hj(z+2, s+4) = -(py * pz) / (r2 * rho);
        Hj(z+2, s+8) =  rho / r2;
    }
    return Hj;
}

static void write_header(std::ofstream& out) {
    for (int i = 0; i < NUM_JOINTS; i++) {
        const std::string& j = BONE_NAMES[i];
        out << j << "_pos_x," << j << "_vel_x," << j << "_acc_x," << j << "_jerk_x,"
            << j << "_pos_y," << j << "_vel_y," << j << "_acc_y," << j << "_jerk_y,"
            << j << "_pos_z," << j << "_vel_z," << j << "_acc_z," << j << "_jerk_z";
        if (i < NUM_JOINTS - 1) out << ",";
    }
    out << "\n";
}

// MAIN
int main() {

    std::cout << "Searching for dataset CSV..." << std::endl;
    std::string csvPath = findCSV();

    if (csvPath.empty()) {
        std::cout << "\n=== CSV NOT FOUND AUTOMATICALLY ===" << std::endl;
        std::cout << "Please type the FULL path to your CSV file and press Enter.\n";
        std::cout << "Your path: ";
        std::getline(std::cin, csvPath);
        std::ifstream test(csvPath);
        if (!test.is_open()) {
            std::cerr << "\nERROR: Cannot open file.\n";
            std::cin.get(); return 1;
        }
        test.close();
    }

    std::cout << "\nFound CSV at:\n  " << csvPath << std::endl;

    std::string outPath = csvPath;
    size_t lastSlash = outPath.find_last_of("\\/");
    outPath = (lastSlash != std::string::npos)
              ? outPath.substr(0, lastSlash + 1) + "ekf_output.csv"
              : "ekf_output.csv";
    std::cout << "Output will be saved to:\n  " << outPath << "\n\n";

    std::ifstream file(csvPath);
    if (!file.is_open()) {
        std::cerr << "ERROR: Cannot open CSV.\n";
        std::cin.get(); return 1;
    }

    std::ofstream ekf_out(outPath);
    if (!ekf_out.is_open()) {
        outPath = "C:\\Users\\Admin\\Desktop\\ekf_output.csv";
        ekf_out.open(outPath);
        if (!ekf_out.is_open()) {
            std::cerr << "ERROR: Cannot write output.\n";
            std::cin.get(); return 1;
        }
        std::cout << "Fallback: writing to Desktop.\n";
    }

    write_header(ekf_out);

    const double dt = 0.01;  // 100 Hz capture rate
    const double sigma_j_sq = 0.001;

    const double sigma_r_sq = 0.1;
    const double sigma_az_sq = 1e-3;

    const double sigma_el_sq = 5e-6;

    const double GATE_SIGMA = 3.0;

    const double ADAPT_THRESH = 1.5;   // metres
    const double ADAPT_SCALE  = 10.0;  // R multiplier for outlier framse

    std::cout << "Building system matrices (276x276)...\n";
    Matrix F       = build_F(dt);
    Matrix Q       = build_Q(dt, sigma_j_sq);
    Matrix R_base  = build_R(sigma_r_sq, sigma_az_sq, sigma_el_sq);
    Matrix I_state = eye(TOTAL_STATES);

    Matrix X(TOTAL_STATES, 1, 0.0);
    Matrix P = eye(TOTAL_STATES) * 1.0;

    std::string line;
    std::getline(file, line);

    int  frameCount   = 0;
    bool isFirstFrame = true;
    std::cout << "Starting EKF processing...\n";

    while (std::getline(file, line)) {
        if (line.empty()) continue;

        std::stringstream ss(line);
        std::string val;
        Matrix Z_cart(MEAS_DIM, 1, 0.0);
        int idx = 0;
        while (std::getline(ss, val, ',') && idx < MEAS_DIM) {
            try   { Z_cart(idx++, 0) = std::stod(val); }
            catch (...) { Z_cart(idx++, 0) = 0.0; }
        }

        if (isFirstFrame) {
            for (int i = 0; i < NUM_JOINTS; ++i) {
                X(i*12,   0) = Z_cart(i*3,   0);
                X(i*12+4, 0) = Z_cart(i*3+1, 0);
                X(i*12+8, 0) = Z_cart(i*3+2, 0);
            }
            isFirstFrame = false;
            for (int i = 0; i < TOTAL_STATES; i++)
                ekf_out << X(i, 0) << (i == TOTAL_STATES-1 ? "" : ",");
            ekf_out << "\n";
            frameCount++;
            continue;
        }

        Matrix X_pred = F * X;
        Matrix P_pred = (F * P * F.transpose()) + Q;

        const double EPS = 1e-9;
        Matrix Z_sph(MEAS_DIM, 1, 0.0);
        for (int i = 0; i < NUM_JOINTS; ++i) {
            double mx = Z_cart(i*3,   0) - SENSOR_OX;
            double my = Z_cart(i*3+1, 0) - SENSOR_OY;
            double mz = Z_cart(i*3+2, 0) - SENSOR_OZ;
            double rho = std::sqrt(mx*mx + my*my + EPS);
            Z_sph(i*3,   0) = std::sqrt(mx*mx + my*my + mz*mz + EPS);
            Z_sph(i*3+1, 0) = manual_arctan2(my, mx);
            Z_sph(i*3+2, 0) = manual_arctan2(mz, rho);
        }

        Matrix Hj = compute_Jacobian(X_pred);
        Matrix Y  = Z_sph - compute_hx(X_pred);

        // Wrap angular residuals to [-π, π] to handle any remaining near-boundary cases
        for (int i = 0; i < NUM_JOINTS; ++i) {
            Y(i*3+1, 0) = wrap_angle(Y(i*3+1, 0));
            Y(i*3+2, 0) = wrap_angle(Y(i*3+2, 0));
        }

        Matrix R_cur = R_base;
        for (int i = 0; i < NUM_JOINTS; ++i) {
            double yr = Y(i*3, 0);
            if (yr < 0.0) yr = -yr;
            if (yr > ADAPT_THRESH) {
                R_cur(i*3,   i*3)   = R_base(i*3,   i*3)   * ADAPT_SCALE;
                R_cur(i*3+1, i*3+1) = R_base(i*3+1, i*3+1) * ADAPT_SCALE;
                R_cur(i*3+2, i*3+2) = R_base(i*3+2, i*3+2) * ADAPT_SCALE;
            }
        }

        Matrix S = (Hj * P_pred * Hj.transpose()) + R_cur;  

        for (int i = 0; i < MEAS_DIM; ++i) {
            double s_std = (S(i, i) > 0.0) ? std::sqrt(S(i, i)) : 1.0;
            double limit = GATE_SIGMA * s_std;
            if (Y(i, 0) >  limit) Y(i, 0) =  limit;
            if (Y(i, 0) < -limit) Y(i, 0) = -limit;
        }

        Matrix PHt = P_pred * Hj.transpose();              
        Matrix K_T = solveCholesky(S, PHt.transpose());    
        Matrix K   = K_T.transpose();                      

        X = X_pred + (K * Y);

        Matrix IKH = I_state - (K * Hj);
        P = (IKH * P_pred * IKH.transpose()) + (K * R_cur * K.transpose());
        enforce_symmetry(P);

        for (int i = 0; i < TOTAL_STATES; i++)
            ekf_out << X(i, 0) << (i == TOTAL_STATES-1 ? "" : ",");
        ekf_out << "\n";

        if (frameCount % 100 == 0) {
            std::cout << "Processed frame " << frameCount << std::endl;
            ekf_out.flush();
        }
        frameCount++;
    }

    ekf_out.close();
    file.close();
    std::cout << "\n=== EKF COMPLETE ===\n";
    std::cout << "Total frames: " << frameCount << "\n";
    std::cout << "Output saved: " << outPath << "\n";
    std::cout << "\nPress Enter to exit...\n";
    std::cin.get();
    return 0;
}