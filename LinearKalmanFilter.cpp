#include <iostream>
#include <vector>
#include <cmath>
#include <fstream>
#include <sstream>
#include <string>
#include <stdexcept>

class Matrix {
public:
    int rows, cols;
    std::vector<double> data;

    Matrix() : rows(0), cols(0) {}

    Matrix(int r, int c, double init_val = 0.0)
        : rows(r), cols(c), data(r* c, init_val) {
    }

    inline double& operator()(int r, int c) {
        return data[r * cols + c];
    }

    inline double operator()(int r, int c) const {
        return data[r * cols + c];
    }

    Matrix operator*(const Matrix& B) const {
        if (cols != B.rows)
            throw std::runtime_error("Matrix multiply: dimension mismatch");
        Matrix C(rows, B.cols, 0.0);
        for (int i = 0; i < rows; ++i)
            for (int k = 0; k < cols; ++k)
                if ((*this)(i, k) != 0.0)
                    for (int j = 0; j < B.cols; ++j)
                        C(i, j) += (*this)(i, k) * B(k, j);
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
        if (rows != B.rows || cols != B.cols)
            throw std::runtime_error("Matrix add: dimension mismatch");
        Matrix C(rows, cols);
        for (size_t i = 0; i < data.size(); ++i)
            C.data[i] = data[i] + B.data[i];
        return C;
    }

    Matrix operator-(const Matrix& B) const {
        if (rows != B.rows || cols != B.cols)
            throw std::runtime_error("Matrix subtract: dimension mismatch");
        Matrix C(rows, cols);
        for (size_t i = 0; i < data.size(); ++i)
            C.data[i] = data[i] - B.data[i];
        return C;
    }
};

Matrix eye(int n) {
    Matrix I(n, n, 0.0);
    for (int i = 0; i < n; ++i) I(i, i) = 1.0;
    return I;
}

Matrix solveCholesky(const Matrix& A, const Matrix& B) {
    int n = A.rows;
    Matrix L(n, n, 0.0);

    for (int i = 0; i < n; i++) {
        for (int j = 0; j <= i; j++) {
            double sum = 0.0;
            if (j == i) {
                for (int k = 0; k < j; k++)
                    sum += L(j, k) * L(j, k);
                double val = A(j, j) - sum;
                L(j, j) = (val > 1e-12) ? std::sqrt(val) : 1e-9;
            }
            else {
                for (int k = 0; k < j; k++)
                    sum += L(i, k) * L(j, k);
                L(i, j) = (A(i, j) - sum) / L(j, j);
            }
        }
    }

    Matrix X(B.rows, B.cols, 0.0);
    for (int c = 0; c < B.cols; c++) {
        std::vector<double> y(n, 0.0);

        for (int i = 0; i < n; i++) {
            double sum = 0.0;
            for (int k = 0; k < i; k++)
                sum += L(i, k) * y[k];
            y[i] = (B(i, c) - sum) / L(i, i);
        }

        for (int i = n - 1; i >= 0; i--) {
            double sum = 0.0;
            for (int k = i + 1; k < n; k++)
                sum += L(k, i) * X(k, c);
            X(i, c) = (y[i] - sum) / L(i, i);
        }
    }
    return X;
}

const int NUM_JOINTS = 23;
const int STATES_PER_JOINT = 12;
const int TOTAL_STATES = NUM_JOINTS * STATES_PER_JOINT;
const int MEAS_DIM = NUM_JOINTS * 3;

const std::string BONE_NAMES[23] = {
    "Pelvis", "L5", "L3", "T12", "T8", "Neck", "Head",
    "RightShoulder", "RightUpperArm", "RightForearm", "RightHand",
    "LeftShoulder",  "LeftUpperArm",  "LeftForearm",  "LeftHand",
    "RightUpperLeg", "RightLowerLeg", "RightFoot", "RightToe",
    "LeftUpperLeg",  "LeftLowerLeg",  "LeftFoot",  "LeftToe"
};

Matrix build_F(double dt) {
    Matrix F(TOTAL_STATES, TOTAL_STATES, 0.0);
    double dt2 = dt * dt;
    double dt3 = dt * dt * dt;

    for (int i = 0; i < NUM_JOINTS; ++i) {
        for (int axis = 0; axis < 3; ++axis) {
            int b = i * 12 + axis * 4;
            F(b, b) = 1.0;
            F(b, b + 1) = dt;
            F(b, b + 2) = dt2 / 2.0;
            F(b, b + 3) = dt3 / 6.0;
            F(b + 1, b + 1) = 1.0;
            F(b + 1, b + 2) = dt;
            F(b + 1, b + 3) = dt2 / 2.0;
            F(b + 2, b + 2) = 1.0;
            F(b + 2, b + 3) = dt;
            F(b + 3, b + 3) = 1.0;
        }
    }
    return F;
}

Matrix build_Q(double dt, double sigma_j_sq = 0.5) {
    Matrix Q(TOTAL_STATES, TOTAL_STATES, 0.0);

    double dt2 = dt * dt;
    double dt3 = dt2 * dt;
    double dt4 = dt3 * dt;
    double dt5 = dt4 * dt;
    double dt6 = dt5 * dt;

    double q[4][4] = {
        { dt6 / 36.0, dt5 / 12.0, dt4 / 6.0, dt3 / 6.0 },
        { dt5 / 12.0, dt4 / 4.0,  dt3 / 2.0, dt2 / 2.0 },
        { dt4 / 6.0,  dt3 / 2.0,  dt2,     dt       },
        { dt3 / 6.0,  dt2 / 2.0,  dt,      1.0      }
    };

    for (int i = 0; i < NUM_JOINTS; ++i) {
        for (int axis = 0; axis < 3; ++axis) {
            int b = i * 12 + axis * 4;
            for (int r = 0; r < 4; ++r)
                for (int c = 0; c < 4; ++c)
                    Q(b + r, b + c) = sigma_j_sq * q[r][c];
        }
    }
    return Q;
}

Matrix build_H() {
    Matrix H(MEAS_DIM, TOTAL_STATES, 0.0);
    for (int i = 0; i < NUM_JOINTS; ++i) {
        H(i * 3, i * 12) = 1.0;
        H(i * 3 + 1, i * 12 + 4) = 1.0;
        H(i * 3 + 2, i * 12 + 8) = 1.0;
    }
    return H;
}

Matrix build_R(double sigma_pos_sq = 0.05) {
    Matrix R(MEAS_DIM, MEAS_DIM, 0.0);
    for (int i = 0; i < MEAS_DIM; ++i)
        R(i, i) = sigma_pos_sq;
    return R;
}

void write_header(std::ofstream& out) {
    for (int i = 0; i < NUM_JOINTS; i++) {
        const std::string& j = BONE_NAMES[i];
        out << j << "_pos_x," << j << "_vel_x," << j << "_acc_x," << j << "_jerk_x,"
            << j << "_pos_y," << j << "_vel_y," << j << "_acc_y," << j << "_jerk_y,"
            << j << "_pos_z," << j << "_vel_z," << j << "_acc_z," << j << "_jerk_z";
        if (i < NUM_JOINTS - 1) out << ",";
    }
    out << "\n";
}

int main() {

    std::ifstream file("3D Full Body Humain Gait Walking Dataset (Noisy Values).csv");
    if (!file.is_open()) {
        std::cerr << "ERROR: Could not open dataset CSV." << std::endl;
        return 1;
    }

    std::ofstream lkf_out("lkf_output.csv");
    if (!lkf_out.is_open()) {
        std::cerr << "ERROR: Could not open output file for writing." << std::endl;
        return 1;
    }

    write_header(lkf_out);

    const double dt = 0.01;
    const double sigma_j_sq = 0.5;
    const double sigma_pos_sq = 0.05;

    std::cout << "Building system matrices..." << std::endl;

    Matrix F = build_F(dt);
    Matrix Q = build_Q(dt, sigma_j_sq);
    Matrix H = build_H();
    Matrix R = build_R(sigma_pos_sq);
    Matrix Ht = H.transpose();
    Matrix I_state = eye(TOTAL_STATES);

    Matrix X(TOTAL_STATES, 1, 0.0);
    Matrix P = eye(TOTAL_STATES);

    std::string line;
    std::getline(file, line);

    int  frameCount = 0;
    bool isFirstFrame = true;

    std::cout << "Starting LKF processing..." << std::endl;

    while (std::getline(file, line)) {
        if (line.empty()) continue;

        std::stringstream ss(line);
        std::string val;
        Matrix Z(MEAS_DIM, 1, 0.0);
        int idx = 0;

        while (std::getline(ss, val, ',') && idx < MEAS_DIM) {
            try {
                Z(idx++, 0) = std::stod(val);
            }
            catch (...) {
                Z(idx++, 0) = 0.0;
            }
        }

        if (isFirstFrame) {
            for (int i = 0; i < NUM_JOINTS; ++i) {
                X(i * 12, 0) = Z(i * 3, 0);
                X(i * 12 + 4, 0) = Z(i * 3 + 1, 0);
                X(i * 12 + 8, 0) = Z(i * 3 + 2, 0);
            }
            isFirstFrame = false;

            for (int i = 0; i < TOTAL_STATES; i++)
                lkf_out << X(i, 0) << (i == TOTAL_STATES - 1 ? "" : ",");
            lkf_out << "\n";
            frameCount++;
            continue;
        }

        Matrix X_pred = F * X;
        Matrix P_pred = (F * P * F.transpose()) + Q;

        Matrix S = (H * P_pred * Ht) + R;

        Matrix PHt = P_pred * Ht;
        Matrix K_T = solveCholesky(S, PHt.transpose());
        Matrix K = K_T.transpose();

        Matrix Y = Z - (H * X_pred);

        X = X_pred + (K * Y);

        Matrix IKH = I_state - (K * H);
        P = (IKH * P_pred * IKH.transpose()) + (K * R * K.transpose());

        for (int i = 0; i < TOTAL_STATES; i++)
            lkf_out << X(i, 0) << (i == TOTAL_STATES - 1 ? "" : ",");
        lkf_out << "\n";

        if (frameCount % 100 == 0) {
            std::cout << "Processed frame " << frameCount << std::endl;
            lkf_out.flush();
        }
        frameCount++;
    }

    lkf_out.close();
    file.close();

    std::cout << "\n=== LKF COMPLETE ===" << std::endl;
    std::cout << "Total frames processed : " << frameCount << std::endl;
    std::cout << "Output written to      : lkf_output.csv" << std::endl;

    return 0;
}