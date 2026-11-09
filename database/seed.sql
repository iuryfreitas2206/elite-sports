-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: localhost    Database: elite_sports
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `categorias`
--

LOCK TABLES `categorias` WRITE;
/*!40000 ALTER TABLE `categorias` DISABLE KEYS */;
INSERT INTO `categorias` (`id_categoria`, `nome`, `descricao`) VALUES (1,'Camisetas','Camisetas esportivas e de treino'),(2,'Shorts','Shorts esportivos e de treino'),(3,'Acessórios','Acessórios esportivos');
/*!40000 ALTER TABLE `categorias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `produtos`
--

LOCK TABLES `produtos` WRITE;
/*!40000 ALTER TABLE `produtos` DISABLE KEYS */;
INSERT INTO `produtos` (`id_produto`, `nome`, `descricao`, `preco`, `id_categoria`, `ativo`, `data_cadastro`, `data_atualizacao`) VALUES (1,'Camiseta Dry Fit','Camiseta esportiva Dry Fit',99.90,1,1,'2026-10-21 15:33:21','2026-10-21 15:33:21'),(2,'Camiseta Treino','Camiseta esportiva para treino',89.90,1,1,'2026-10-21 15:33:21','2026-10-21 15:33:21'),(3,'Regata Fitness','Regata esportiva para treino',69.90,1,1,'2026-10-21 15:33:21','2026-10-21 15:33:21'),(4,'Short Esportivo','Short esportivo para treino e academia',79.90,2,1,'2026-10-21 15:33:21','2026-10-22 20:49:54'),(5,'Bola Elite Stars','Bola esportiva Elite Stars',179.90,3,1,'2026-10-21 15:33:21','2026-10-21 15:33:21'),(6,'Bola Elite Nations','Bola esportiva Elite Nations',159.90,3,1,'2026-10-21 15:33:21','2026-10-21 15:33:21'),(7,'Bola Elite Pro','Bola esportiva Elite Pro',129.90,3,1,'2026-10-22 20:31:29','2026-10-22 20:31:29'),(8,'Garrafa Esportiva Elite 750ml','Garrafa esportiva Elite 750ml',79.90,3,1,'2026-10-22 20:31:29','2026-10-22 20:31:29'),(9,'Bolsa Esportiva Elite','Bolsa esportiva Elite',149.90,3,1,'2026-10-22 20:31:29','2026-10-22 20:31:29'),(10,'Mochila Esportiva Elite','Mochila esportiva Elite',189.90,3,1,'2026-10-22 20:31:29','2026-10-22 20:31:29'),(11,'Meia Esportiva Elite','Meia esportiva Elite',39.90,3,1,'2026-10-22 20:31:29','2026-10-22 20:31:29');
/*!40000 ALTER TABLE `produtos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `produto_variacoes`
--

LOCK TABLES `produto_variacoes` WRITE;
/*!40000 ALTER TABLE `produto_variacoes` DISABLE KEYS */;
INSERT INTO `produto_variacoes` (`id_variacao`, `id_produto`, `cor`, `tamanho`, `estoque`, `imagem`, `sku`) VALUES (1,1,'azul','P',30,'./img/camiseta-dryfit/DryFit-azul-1.png','DRY-AZ-P'),(2,1,'azul','M',30,'./img/camiseta-dryfit/DryFit-azul-1.png','DRY-AZ-M'),(3,1,'azul','G',30,'./img/camiseta-dryfit/DryFit-azul-1.png','DRY-AZ-G'),(4,1,'azul','GG',30,'./img/camiseta-dryfit/DryFit-azul-1.png','DRY-AZ-GG'),(5,1,'branco','P',30,'./img/camiseta-dryfit/DryFit-branca-1.png','DRY-BR-P'),(6,1,'branco','M',30,'./img/camiseta-dryfit/DryFit-branca-1.png','DRY-BR-M'),(7,1,'branco','G',30,'./img/camiseta-dryfit/DryFit-branca-1.png','DRY-BR-G'),(8,1,'branco','GG',30,'./img/camiseta-dryfit/DryFit-branca-1.png','DRY-BR-GG'),(9,1,'preto','P',30,'./img/camiseta-dryfit/DryFit-preta-1.png','DRY-PR-P'),(10,1,'preto','M',30,'./img/camiseta-dryfit/DryFit-preta-1.png','DRY-PR-M'),(11,1,'preto','G',30,'./img/camiseta-dryfit/DryFit-preta-1.png','DRY-PR-G'),(12,1,'preto','GG',30,'./img/camiseta-dryfit/DryFit-preta-1.png','DRY-PR-GG'),(13,2,'preto','P',30,'./img/camiseta-treino/Camiseta treino-preta-1.png','TREINO-PR-P'),(14,2,'preto','M',30,'./img/camiseta-treino/Camiseta treino-preta-1.png','TREINO-PR-M'),(15,2,'preto','G',30,'./img/camiseta-treino/Camiseta treino-preta-1.png','TREINO-PR-G'),(16,2,'preto','GG',30,'./img/camiseta-treino/Camiseta treino-preta-1.png','TREINO-PR-GG'),(17,3,'preto','P',20,'./img/regata/Regata-Preta-1.png','REG-PR-P'),(18,3,'preto','M',20,'./img/regata/Regata-Preta-1.png','REG-PR-M'),(19,3,'preto','G',20,'./img/regata/Regata-Preta-1.png','REG-PR-G'),(20,3,'preto','GG',20,'./img/regata/Regata-Preta-1.png','REG-PR-GG'),(21,4,'azul','P',25,'./img/short-esportivo/Short-Azul-1.png','SHORT-AZ-P'),(22,4,'azul','M',25,'./img/short-esportivo/Short-Azul-1.png','SHORT-AZ-M'),(23,4,'azul','G',25,'./img/short-esportivo/Short-Azul-1.png','SHORT-AZ-G'),(24,4,'azul','GG',24,'./img/short-esportivo/Short-Azul-1.png','SHORT-AZ-GG'),(25,4,'branco','P',24,'./img/short-esportivo/Short-Branco-1.png','SHORT-BR-P'),(26,4,'branco','M',25,'./img/short-esportivo/Short-Branco-1.png','SHORT-BR-M'),(27,4,'branco','G',25,'./img/short-esportivo/Short-Branco-1.png','SHORT-BR-G'),(28,4,'branco','GG',25,'./img/short-esportivo/Short-Branco-1.png','SHORT-BR-GG'),(29,4,'preto','P',25,'./img/short-esportivo/Short-Preto-1.png','SHORT-PR-P'),(30,4,'preto','M',25,'./img/short-esportivo/Short-Preto-1.png','SHORT-PR-M'),(31,4,'preto','G',22,'./img/short-esportivo/Short-Preto-1.png','SHORT-PR-G'),(32,4,'preto','GG',25,'./img/short-esportivo/Short-Preto-1.png','SHORT-PR-GG'),(33,5,'Única',NULL,25,'./img/acessorios/Bola_futebol_2.png','BOLA-STARS'),(34,6,'Única',NULL,25,'./img/acessorios/Bola_futebol_1.png','BOLA-NATIONS'),(35,2,'azul','P',30,'./img/camiseta-treino/Camiseta treino-azul-3.png',NULL),(36,2,'azul','M',30,'./img/camiseta-treino/Camiseta treino-azul-3.png',NULL),(37,2,'azul','G',30,'./img/camiseta-treino/Camiseta treino-azul-3.png',NULL),(38,2,'azul','GG',30,'./img/camiseta-treino/Camiseta treino-azul-3.png',NULL),(42,2,'branco','P',30,'./img/camiseta-treino/Camiseta treino-branca-1.png',NULL),(43,2,'branco','M',30,'./img/camiseta-treino/Camiseta treino-branca-1.png',NULL),(44,2,'branco','G',30,'./img/camiseta-treino/Camiseta treino-branca-1.png',NULL),(45,2,'branco','GG',30,'./img/camiseta-treino/Camiseta treino-branca-1.png',NULL),(49,3,'azul','P',20,'./img/regata/Regata-Azul-1.png',NULL),(50,3,'azul','M',20,'./img/regata/Regata-Azul-1.png',NULL),(51,3,'azul','G',20,'./img/regata/Regata-Azul-1.png',NULL),(52,3,'azul','GG',20,'./img/regata/Regata-Azul-1.png',NULL),(56,3,'branco','P',20,'./img/regata/Regata-Branca-1.png',NULL),(57,3,'branco','M',20,'./img/regata/Regata-Branca-1.png',NULL),(58,3,'branco','G',20,'./img/regata/Regata-Branca-1.png',NULL),(59,3,'branco','GG',20,'./img/regata/Regata-Branca-1.png',NULL),(63,7,'Única',NULL,25,'./img/acessorios/Bola_futebol_3.png','BOLA-PRO-UNICA'),(64,8,'preto',NULL,25,'./img/acessorios/Garrafa_preta_1.png','GARRAFA-750-PRETO'),(65,8,'azul',NULL,25,'./img/acessorios/Garrafa_azul_1.png','GARRAFA-750-AZUL'),(66,8,'branco',NULL,25,'./img/acessorios/Garrafa_branca_1.png','GARRAFA-750-BRANCO'),(67,9,'preto',NULL,25,'./img/acessorios/Bolsa_preta_1.png','BOLSA-PRETO'),(68,9,'azul',NULL,25,'./img/acessorios/Bolsa_azul_1.png','BOLSA-AZUL'),(69,9,'branco',NULL,25,'./img/acessorios/Bolsa_branca_1.png','BOLSA-BRANCO'),(70,10,'preto',NULL,25,'./img/acessorios/Mochila_preta_1.png','MOCHILA-PRETO'),(71,10,'azul',NULL,25,'./img/acessorios/Mochila_azul_1.png','MOCHILA-AZUL'),(72,10,'branco',NULL,25,'./img/acessorios/Mochila_branca_1.png','MOCHILA-BRANCO'),(73,11,'preto',NULL,25,'./img/acessorios/Meia_preta_1.png','MEIA-PRETO'),(74,11,'branco',NULL,25,'./img/acessorios/Meia_branca_1.png','MEIA-BRANCO');
/*!40000 ALTER TABLE `produto_variacoes` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-09 14:08:52
