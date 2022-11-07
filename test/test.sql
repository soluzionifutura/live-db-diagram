CREATE TABLE "Regions" (
    "id" SERIAL,
    "name" VARCHAR(255),

    PRIMARY KEY("id")
);

CREATE TABLE "Cities" (
    "id" SERIAL,
    "name" VARCHAR(255),
    "abbreviation" VARCHAR(255),
    "geographicalLocation" VARCHAR(255),
    "regionId" INT,

    PRIMARY KEY("id"),
    FOREIGN KEY("regionId") REFERENCES "Regions"("id")
);

CREATE TABLE "Municipalities" (
    "id" SERIAL,
    "name" VARCHAR(255),
    "latitude" REAL,
    "longitude" REAL,
    "cityId" INT,
    "parmigianoReggianoDistrict" BOOLEAN,
    "granaPadanoDistrict" BOOLEAN,

    PRIMARY KEY("id"),
    FOREIGN KEY("cityId") REFERENCES "Cities"("id")
);

CREATE TABLE IF NOT EXISTS "Users" (
  "id" SERIAL PRIMARY KEY,
  "email" VARCHAR(255) NOT NULL UNIQUE,
  "firstname" VARCHAR(255) NOT NULL,
  "lastname" VARCHAR(255) NOT NULL,
  "status" VARCHAR(255) NOT NULL,
  "password" VARCHAR(255) NOT NULL,
  "creationTimestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "lastEditTimestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "lastAccess" TIMESTAMP DEFAULT NULL,
  "admin" BOOLEAN DEFAULT FALSE,
  "orderRequestNotifications" BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS "Organizations" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255),
  "alias" VARCHAR(255) UNIQUE NOT NULL,
  "creationTimestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "lastEditTimestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "auaCode" VARCHAR(255) UNIQUE,
  "address" VARCHAR(255) NOT NULL,
  "aslCode" VARCHAR(255) UNIQUE NOT NULL,
  "region" VARCHAR(255) NOT NULL,
  "city" VARCHAR(255) NOT NULL,
  "municipality" VARCHAR(255) NOT NULL,
  "latitude" REAL,
  "longitude" REAL,
  "postalCode" VARCHAR(255) NOT NULL,
  "closed" BOOLEAN NOT NULL DEFAULT FALSE,
  "stableSettedUp" BOOLEAN NOT NULL DEFAULT FALSE,
  "imageKey" VARCHAR(255) DEFAULT NULL,
  "stripeCustomerId" VARCHAR(255) UNIQUE,
  "district" VARCHAR(255) DEFAULT 'NONE'
);

CREATE TABLE IF NOT EXISTS "OrganizationsUsersTh" (
  "userId" INT UNIQUE REFERENCES "Users"("id"),
  "organizationId" INT REFERENCES "Organizations"("id"),
  "role" VARCHAR(255) NOT NULL,
  PRIMARY KEY("userId", "organizationId")
);

CREATE TABLE IF NOT EXISTS "Cattle" (
  "id" SERIAL PRIMARY KEY,
  "auaCode" VARCHAR(255) DEFAULT NULL,
  "name" VARCHAR(255),
  "serialNumber" VARCHAR(255) UNIQUE NOT NULL,
  "sourceType" VARCHAR(255) NOT NULL,
  "gpftData" JSONB
);

CREATE TABLE IF NOT EXISTS "CattleProductionData" (
  "year" INT,
  "cattleSerialNumber" VARCHAR(255),
  "nl" INT,
  "productionData" JSONB,

  PRIMARY KEY("year", "cattleSerialNumber", "nl"),
  FOREIGN KEY("cattleSerialNumber") REFERENCES "Cattle"("serialNumber")
);

CREATE TABLE IF NOT EXISTS "CattleOrganizationsTh" (
  "organizationId" INT REFERENCES "Organizations"("id"),
  "cattleId" INT UNIQUE REFERENCES "Cattle"("id"),
  PRIMARY KEY("organizationId", "cattleId")
);

CREATE TABLE IF NOT EXISTS "Catalogs" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "organizationId" INT NOT NULL REFERENCES "Organizations"("id"),
  "visibility" VARCHAR(255) NOT NULL DEFAULT 'PRIVATE',
  "description" TEXT,
  "creationTimestamp" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lastEditTimestamp" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "authorUserId" INT NOT NULL REFERENCES "Users"("id")
);

CREATE TABLE IF NOT EXISTS "CattleCatalogsTh" (
  -- a cattle could be in several catalogs
  "catalogId" INT REFERENCES "Catalogs"("id"),
  "cattleId" INT REFERENCES "Cattle"("id"),
  -- "price" REAL DEFAULT NULL,
  "discount" JSONB,
  "priceVisible" BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY("catalogId", "cattleId")
);

CREATE TABLE IF NOT EXISTS "OrderRequests" (
  "id" SERIAL PRIMARY KEY,
  "authorUserId" INT NOT NULL REFERENCES "Users"("id"),
  "creationTimestamp" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lastEditTimestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "cattleCount" INT NOT NULL DEFAULT 0,
  "sellerOrganizationId" INT NOT NULL REFERENCES "Organizations"("id"),
  "buyerOrganizationId" INT NOT NULL REFERENCES "Organizations"("id"),
  "status" VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS "OrderRequestActions" (
  "id" SERIAL PRIMARY KEY,
  "orderRequestId" INT REFERENCES "OrderRequests"("id"),
  "timestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "type" VARCHAR(255) NOT NULL,
  "annotation" TEXT,
  "cattleId" INT DEFAULT NULL,
  "catalogId" INT DEFAULT NULL,
  "discount" JSONB,
  "active" BOOLEAN,
  "price" DOUBLE PRECISION,
  "authorUserId" INT REFERENCES "Users"("id"),
  "isAutomaticAction" BOOLEAN NOT NULL DEFAULT FALSE,
  "onlyVisibleToSeller" BOOLEAN DEFAULT false,
  "priceVisible" BOOLEAN,
  FOREIGN KEY ("catalogId") REFERENCES "Catalogs"("id"),
  FOREIGN KEY ("cattleId") REFERENCES "Cattle"("id")
);

CREATE TABLE IF NOT EXISTS "PremiumSubscriptions" (
  "customerId" VARCHAR(255) REFERENCES "Organizations"("stripeCustomerId"),
  "eventId" VARCHAR(255) NOT NULL,
  "timestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "eventType" VARCHAR(255) NOT NULL,
  "payload" JSONB NOT NULL,
  "status" VARCHAR(255) NOT NULL,
  PRIMARY KEY("customerId", "eventId")
);

CREATE TABLE IF NOT EXISTS "CronActions" (
  "name" VARCHAR(255),
  "cronExpression" VARCHAR(255),
  "lastExecution" TIMESTAMPTZ,
  "enabled" BOOLEAN,
  "additionalParameters" JSONB NOT NULL DEFAULT '{}'::JSONB,
  PRIMARY KEY("name")
);

CREATE TABLE IF NOT EXISTS "TopCattle" (
  "id" SERIAL,
  "cattle" JSONB,
  "timestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY("id")
);

-- CREATE OR REPLACE FUNCTION calculate_distance(lat1 float, lon1 float, lat2 float, lon2 float, units varchar)
-- RETURNS float AS $$dist$
--     DECLARE
--         dist float = 0;
--         radlat1 float;
--         radlat2 float;
--         theta float;
--         radtheta float;
--     BEGIN
--         IF lat1 = lat2 AND lon1 = lon2
--             THEN RETURN dist;
--         ELSE
--             radlat1 = pi() * lat1 / 180;
--             radlat2 = pi() * lat2 / 180;
--             theta = lon1 - lon2;
--             radtheta = pi() * theta / 180;
--             dist = sin(radlat1) * sin(radlat2) + cos(radlat1) * cos(radlat2) * cos(radtheta);

--             IF dist > 1 THEN dist = 1; END IF;

--             dist = acos(dist);
--             dist = dist * 180 / pi();
--             dist = dist * 60 * 1.1515;

--             IF units = 'K' THEN dist = dist * 1.609344; END IF;
--             IF units = 'N' THEN dist = dist * 0.8684; END IF;

--             RETURN dist;
--         END IF;
--     END;

-- $dist$ LANGUAGE plpgsql;
