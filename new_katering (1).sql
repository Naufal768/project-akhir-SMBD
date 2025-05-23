-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 23, 2025 at 03:32 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `new_katering`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_pesanan_by_pelanggan` (IN `pid` INT)   BEGIN
    SELECT p.id_pesanan, m.nama_menu, p.tanggal
    FROM pesanan p
    JOIN menu m ON p.id_menu = m.id_menu
    WHERE p.id_pelanggan = pid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_rekap_tanggal` (IN `tgl` DATE)   BEGIN
    SELECT 
        p.id_pesanan,
        pl.nama_pelanggan,
        m.nama_menu,
        pb.status_bayar,
        pb.total
    FROM pesanan p
    JOIN menu m ON p.id_menu = m.id_menu
    JOIN pelanggan pl ON p.id_pelanggan = pl.id_pelanggan
    JOIN pembayaran pb ON p.id_pesanan = pb.id_pesanan
    WHERE p.tanggal = tgl;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_total_pendapatan_by_status` (IN `p_status` VARCHAR(20))   BEGIN
    SELECT 
        p_status AS status_yang_dihitung,
        SUM(total) AS total_pembayaran
    FROM pembayaran
    WHERE status_bayar = p_status;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_pesanan_dan_pembayaran` (IN `pid_pelanggan` INT, IN `pid_menu` INT, IN `metode` VARCHAR(50))   BEGIN
    DECLARE total DECIMAL(10,2);
    DECLARE pid_pesanan INT;

    -- Simpan pesanan
    INSERT INTO pesanan (id_pelanggan, id_menu, nama_menu, tanggal)
    SELECT pid_pelanggan, id_menu, nama_menu, CURDATE()
    FROM menu WHERE id_menu = pid_menu;

    -- Ambil id_pesanan terakhir
    SET pid_pesanan = LAST_INSERT_ID();

    -- Ambil harga menu
    SELECT harga INTO total FROM menu WHERE id_menu = pid_menu;

    -- Simpan ke pembayaran
    INSERT INTO pembayaran (metode_pembayaran, total, status_bayar, id_pesanan)
    VALUES (metode, total, 'Belum Lunas', pid_pesanan);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_pembayaran_masif` ()   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE pid INT;
    DECLARE cur CURSOR FOR
        SELECT id_pembayaran FROM pembayaran WHERE total > 50000 AND status_bayar = 'Belum Lunas';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO pid;
        IF done THEN
            LEAVE read_loop;
        END IF;

        UPDATE pembayaran SET status_bayar = 'Lunas' WHERE id_pembayaran = pid;
    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `kategori`
--

CREATE TABLE `kategori` (
  `id_kategori` int(11) NOT NULL,
  `nama_kategori` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `kategori`
--

INSERT INTO `kategori` (`id_kategori`, `nama_kategori`) VALUES
(1, 'Makanan'),
(2, 'Minuman'),
(3, 'Dessert'),
(4, 'Snack'),
(5, 'Paket');

-- --------------------------------------------------------

--
-- Table structure for table `menu`
--

CREATE TABLE `menu` (
  `id_menu` int(11) NOT NULL,
  `nama_menu` varchar(100) NOT NULL,
  `harga` decimal(10,2) NOT NULL,
  `id_kategori` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `menu`
--

INSERT INTO `menu` (`id_menu`, `nama_menu`, `harga`, `id_kategori`) VALUES
(1, 'Nasi Goreng', 15000.00, 1),
(2, 'Tahu Kocek Kesukaan', 5000.00, 2),
(3, 'Pudding Coklat', 8000.00, 3),
(4, 'Kentang Goreng', 10000.00, 4),
(5, 'Paket Spesial', 25000.00, 5);

--
-- Triggers `menu`
--
DELIMITER $$
CREATE TRIGGER `after_update_menu` AFTER UPDATE ON `menu` FOR EACH ROW BEGIN
  -- Periksa apakah nama_menu mengalami perubahan
  IF NEW.nama_menu <> OLD.nama_menu THEN
    UPDATE pesanan
    SET nama_menu = NEW.nama_menu
    WHERE id_menu = NEW.id_menu;
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `pelanggan`
--

CREATE TABLE `pelanggan` (
  `id_pelanggan` int(11) NOT NULL,
  `nama_pelanggan` varchar(100) NOT NULL,
  `no_telp` varchar(20) DEFAULT NULL,
  `alamat` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pelanggan`
--

INSERT INTO `pelanggan` (`id_pelanggan`, `nama_pelanggan`, `no_telp`, `alamat`) VALUES
(1, 'Andi', '081234567895', 'Jl. Merdeka No. 10'),
(2, 'Budi', '081298669999', 'Jl. Diponegoro No. 15'),
(4, 'Dian', '082298765431', 'Jl. Sudirman No. 5'),
(5, 'Eka', '083112233445', 'Jl. Gatot Subroto No. 7'),
(6, 'Fajar', '081234567891', 'Jl. Pelajar Pejuang 45'),
(7, 'Surya', '081234567891', 'Jl. Pejuang Rupiah 45'),
(8, 'Ibnu', '081234567891', 'Jl. Pejuang Rupiah 45'),
(10, 'Naufal', '081515686325', 'Lamon');

--
-- Triggers `pelanggan`
--
DELIMITER $$
CREATE TRIGGER `after_delete_pelanggan` AFTER DELETE ON `pelanggan` FOR EACH ROW BEGIN
    DELETE FROM pesanan WHERE id_pelanggan = OLD.id_pelanggan;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_insert_pelanggan_to_pesanan` AFTER INSERT ON `pelanggan` FOR EACH ROW BEGIN
    INSERT INTO pesanan (id_pelanggan, id_menu, nama_menu, tanggal)
    VALUES (NEW.id_pelanggan, null, "belum pesan", CURDATE());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_insert_pelanggan` BEFORE INSERT ON `pelanggan` FOR EACH ROW BEGIN
    IF NOT (NEW.no_telp LIKE '08%' OR NEW.no_telp LIKE '+62%') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nomor telepon harus diawali dengan 08 atau +62';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_update_pelanggan` BEFORE UPDATE ON `pelanggan` FOR EACH ROW BEGIN
    IF CHAR_LENGTH(NEW.no_telp) < 12 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nomor telepon tidak boleh kurang dari 12 karakter';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `pembayaran`
--

CREATE TABLE `pembayaran` (
  `id_pembayaran` int(11) NOT NULL,
  `metode_pembayaran` varchar(50) NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `status_bayar` enum('Belum Lunas','Lunas') DEFAULT 'Belum Lunas',
  `id_pesanan` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pembayaran`
--

INSERT INTO `pembayaran` (`id_pembayaran`, `metode_pembayaran`, `total`, `status_bayar`, `id_pesanan`) VALUES
(1, 'E-Wallet', 15000.00, 'Lunas', 1),
(2, 'QRIS', 5000.00, 'Belum Lunas', 2),
(4, 'Tunai', 10000.00, 'Lunas', 4),
(5, 'QRIS', 55000.00, 'Lunas', 5),
(6, 'QRIS', 500000.00, 'Lunas', 8),
(7, 'QRIS', 55000.00, 'Lunas', 9),
(8, 'QRIS', 8000.00, 'Lunas', 10),
(9, 'Transfer', 15000.00, 'Belum Lunas', 14),
(10, 'Transfer', 25000.00, 'Belum Lunas', 15),
(11, 'E-Wallet', 8000.00, 'Belum Lunas', 16),
(13, 'Tunai', 5000.00, 'Belum Lunas', 18);

--
-- Triggers `pembayaran`
--
DELIMITER $$
CREATE TRIGGER `before_delete_pembayaran` BEFORE DELETE ON `pembayaran` FOR EACH ROW BEGIN
    IF OLD.status_bayar = 'Belum Lunas' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tidak boleh dihapus karena status pembayaran masih Belum Lunas';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `pesanan`
--

CREATE TABLE `pesanan` (
  `id_pesanan` int(11) NOT NULL,
  `id_pelanggan` int(11) DEFAULT NULL,
  `id_menu` int(11) DEFAULT NULL,
  `nama_menu` varchar(100) DEFAULT NULL,
  `tanggal` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pesanan`
--

INSERT INTO `pesanan` (`id_pesanan`, `id_pelanggan`, `id_menu`, `nama_menu`, `tanggal`) VALUES
(1, 1, 1, 'Nasi Goreng', '2025-05-20'),
(2, 2, 2, 'Tahu Kocek Kesukaan', '2025-05-20'),
(4, 4, 4, 'Kentang Goreng', '2025-05-19'),
(5, 5, 5, 'Paket Spesial', '2025-05-18'),
(6, 8, 2, 'Tahu Kocek', '2025-05-20'),
(7, 2, 4, 'Kentang Goreng', '2025-05-20'),
(8, 1, 2, 'Tahu Kocek Kesukaan', '2025-05-21'),
(9, 2, 2, 'Tahu Kocek Kesukaan', '2025-05-21'),
(10, 8, 3, 'Pudding Coklat', '2025-05-16'),
(13, 8, 1, 'nasi goreng', '2025-05-21'),
(14, 6, 1, 'Nasi Goreng', '2025-05-22'),
(15, 5, 5, 'Paket Spesial', '2025-05-22'),
(16, 8, 3, 'Pudding Coklat', '2025-05-22'),
(17, 1, 3, 'Pudding Coklat', '2025-05-22'),
(18, 6, 2, 'Tahu Kocek Kesukaan', '2025-05-22'),
(21, 10, NULL, 'belum pesan', '2025-05-22');

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_menu_terlaris`
-- (See below for the actual view)
--
CREATE TABLE `view_menu_terlaris` (
`id_menu` int(11)
,`nama_menu` varchar(100)
,`jumlah_pesanan` bigint(21)
,`harga` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_pelanggan_aktif`
-- (See below for the actual view)
--
CREATE TABLE `view_pelanggan_aktif` (
`id_pelanggan` int(11)
,`nama_pelanggan` varchar(100)
,`total_pesanan` bigint(21)
,`terakhir_pesan` date
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_pembayaran_lengkap`
-- (See below for the actual view)
--
CREATE TABLE `view_pembayaran_lengkap` (
`id_pembayaran` int(11)
,`metode_pembayaran` varchar(50)
,`total` decimal(10,2)
,`status_bayar` enum('Belum Lunas','Lunas')
,`tanggal` date
,`nama_menu` varchar(100)
,`nama_pelanggan` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_pesanan_belum_lunas`
-- (See below for the actual view)
--
CREATE TABLE `view_pesanan_belum_lunas` (
`id_pembayaran` int(11)
,`id_pesanan` int(11)
,`nama_pelanggan` varchar(100)
,`nama_menu` varchar(100)
,`total` decimal(10,2)
,`status_bayar` enum('Belum Lunas','Lunas')
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_pesanan_hari_ini`
-- (See below for the actual view)
--
CREATE TABLE `view_pesanan_hari_ini` (
`id_pesanan` int(11)
,`nama_pelanggan` varchar(100)
,`nama_menu` varchar(100)
,`harga` decimal(10,2)
,`tanggal` date
);

-- --------------------------------------------------------

--
-- Structure for view `view_menu_terlaris`
--
DROP TABLE IF EXISTS `view_menu_terlaris`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_menu_terlaris`  AS SELECT `m`.`id_menu` AS `id_menu`, `m`.`nama_menu` AS `nama_menu`, count(`p`.`id_pesanan`) AS `jumlah_pesanan`, `m`.`harga` AS `harga` FROM (`menu` `m` left join `pesanan` `p` on(`m`.`id_menu` = `p`.`id_menu`)) GROUP BY `m`.`id_menu`, `m`.`nama_menu`, `m`.`harga` ORDER BY count(`p`.`id_pesanan`) DESC ;

-- --------------------------------------------------------

--
-- Structure for view `view_pelanggan_aktif`
--
DROP TABLE IF EXISTS `view_pelanggan_aktif`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_pelanggan_aktif`  AS SELECT `pl`.`id_pelanggan` AS `id_pelanggan`, `pl`.`nama_pelanggan` AS `nama_pelanggan`, count(`p`.`id_pesanan`) AS `total_pesanan`, max(`p`.`tanggal`) AS `terakhir_pesan` FROM (`pelanggan` `pl` join `pesanan` `p` on(`pl`.`id_pelanggan` = `p`.`id_pelanggan`)) GROUP BY `pl`.`id_pelanggan`, `pl`.`nama_pelanggan` ORDER BY count(`p`.`id_pesanan`) DESC ;

-- --------------------------------------------------------

--
-- Structure for view `view_pembayaran_lengkap`
--
DROP TABLE IF EXISTS `view_pembayaran_lengkap`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_pembayaran_lengkap`  AS SELECT `pb`.`id_pembayaran` AS `id_pembayaran`, `pb`.`metode_pembayaran` AS `metode_pembayaran`, `pb`.`total` AS `total`, `pb`.`status_bayar` AS `status_bayar`, `ps`.`tanggal` AS `tanggal`, `ps`.`nama_menu` AS `nama_menu`, `pl`.`nama_pelanggan` AS `nama_pelanggan` FROM ((`pembayaran` `pb` join `pesanan` `ps` on(`pb`.`id_pesanan` = `ps`.`id_pesanan`)) join `pelanggan` `pl` on(`ps`.`id_pelanggan` = `pl`.`id_pelanggan`)) ;

-- --------------------------------------------------------

--
-- Structure for view `view_pesanan_belum_lunas`
--
DROP TABLE IF EXISTS `view_pesanan_belum_lunas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_pesanan_belum_lunas`  AS SELECT `pb`.`id_pembayaran` AS `id_pembayaran`, `ps`.`id_pesanan` AS `id_pesanan`, `pl`.`nama_pelanggan` AS `nama_pelanggan`, `ps`.`nama_menu` AS `nama_menu`, `pb`.`total` AS `total`, `pb`.`status_bayar` AS `status_bayar` FROM ((`pembayaran` `pb` join `pesanan` `ps` on(`pb`.`id_pesanan` = `ps`.`id_pesanan`)) join `pelanggan` `pl` on(`ps`.`id_pelanggan` = `pl`.`id_pelanggan`)) WHERE `pb`.`status_bayar` = 'Belum Lunas' ;

-- --------------------------------------------------------

--
-- Structure for view `view_pesanan_hari_ini`
--
DROP TABLE IF EXISTS `view_pesanan_hari_ini`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_pesanan_hari_ini`  AS SELECT `p`.`id_pesanan` AS `id_pesanan`, `pl`.`nama_pelanggan` AS `nama_pelanggan`, `p`.`nama_menu` AS `nama_menu`, `m`.`harga` AS `harga`, `p`.`tanggal` AS `tanggal` FROM ((`pesanan` `p` join `pelanggan` `pl` on(`p`.`id_pelanggan` = `pl`.`id_pelanggan`)) join `menu` `m` on(`p`.`id_menu` = `m`.`id_menu`)) WHERE `p`.`tanggal` = curdate() ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `kategori`
--
ALTER TABLE `kategori`
  ADD PRIMARY KEY (`id_kategori`);

--
-- Indexes for table `menu`
--
ALTER TABLE `menu`
  ADD PRIMARY KEY (`id_menu`),
  ADD KEY `id_kategori` (`id_kategori`);

--
-- Indexes for table `pelanggan`
--
ALTER TABLE `pelanggan`
  ADD PRIMARY KEY (`id_pelanggan`);

--
-- Indexes for table `pembayaran`
--
ALTER TABLE `pembayaran`
  ADD PRIMARY KEY (`id_pembayaran`),
  ADD KEY `pembayaran_ibfk_1` (`id_pesanan`);

--
-- Indexes for table `pesanan`
--
ALTER TABLE `pesanan`
  ADD PRIMARY KEY (`id_pesanan`),
  ADD KEY `id_menu` (`id_menu`),
  ADD KEY `pesanan_ibfk_1` (`id_pelanggan`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `kategori`
--
ALTER TABLE `kategori`
  MODIFY `id_kategori` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `menu`
--
ALTER TABLE `menu`
  MODIFY `id_menu` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `pelanggan`
--
ALTER TABLE `pelanggan`
  MODIFY `id_pelanggan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `pembayaran`
--
ALTER TABLE `pembayaran`
  MODIFY `id_pembayaran` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `pesanan`
--
ALTER TABLE `pesanan`
  MODIFY `id_pesanan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `menu`
--
ALTER TABLE `menu`
  ADD CONSTRAINT `menu_ibfk_1` FOREIGN KEY (`id_kategori`) REFERENCES `kategori` (`id_kategori`);

--
-- Constraints for table `pembayaran`
--
ALTER TABLE `pembayaran`
  ADD CONSTRAINT `pembayaran_ibfk_1` FOREIGN KEY (`id_pesanan`) REFERENCES `pesanan` (`id_pesanan`) ON DELETE CASCADE;

--
-- Constraints for table `pesanan`
--
ALTER TABLE `pesanan`
  ADD CONSTRAINT `pesanan_ibfk_1` FOREIGN KEY (`id_pelanggan`) REFERENCES `pelanggan` (`id_pelanggan`) ON DELETE CASCADE,
  ADD CONSTRAINT `pesanan_ibfk_2` FOREIGN KEY (`id_menu`) REFERENCES `menu` (`id_menu`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
