--
-- PostgreSQL database dump
--

\restrict AlCUGwJ1E20YkyZdRLHxmUJgTyO9vrnaHfHG1XgMbqAv0XQfg2h6m5YDcM9LVY4

-- Dumped from database version 15.14 (Homebrew)
-- Dumped by pg_dump version 15.14 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: attribute_options; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.attribute_options (
    option_id integer NOT NULL,
    attribute_id integer NOT NULL,
    option_value character varying(200) NOT NULL,
    option_label character varying(200) NOT NULL,
    display_order integer,
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.attribute_options OWNER TO myuser;

--
-- Name: attribute_options_option_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.attribute_options_option_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attribute_options_option_id_seq OWNER TO myuser;

--
-- Name: attribute_options_option_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.attribute_options_option_id_seq OWNED BY public.attribute_options.option_id;


--
-- Name: attribute_sets; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.attribute_sets (
    attribute_set_id integer NOT NULL,
    set_code character varying(50) NOT NULL,
    set_name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.attribute_sets OWNER TO myuser;

--
-- Name: attribute_sets_attribute_set_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.attribute_sets_attribute_set_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attribute_sets_attribute_set_id_seq OWNER TO myuser;

--
-- Name: attribute_sets_attribute_set_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.attribute_sets_attribute_set_id_seq OWNED BY public.attribute_sets.attribute_set_id;


--
-- Name: attributes; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.attributes (
    attribute_id integer NOT NULL,
    attribute_code character varying(100) NOT NULL,
    attribute_name character varying(200) NOT NULL,
    attribute_type character varying(30) NOT NULL,
    data_type character varying(20),
    unit_of_measure character varying(20),
    is_filterable boolean DEFAULT false,
    is_searchable boolean DEFAULT false,
    is_comparable boolean DEFAULT false,
    validation_rules text,
    display_order integer,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.attributes OWNER TO myuser;

--
-- Name: attributes_attribute_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.attributes_attribute_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attributes_attribute_id_seq OWNER TO myuser;

--
-- Name: attributes_attribute_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.attributes_attribute_id_seq OWNED BY public.attributes.attribute_id;


--
-- Name: brands; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.brands (
    brand_id integer NOT NULL,
    brand_code character varying(50) NOT NULL,
    brand_name character varying(100) NOT NULL,
    brand_logo_url character varying(500),
    website_url character varying(255),
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.brands OWNER TO myuser;

--
-- Name: brands_brand_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.brands_brand_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.brands_brand_id_seq OWNER TO myuser;

--
-- Name: brands_brand_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.brands_brand_id_seq OWNED BY public.brands.brand_id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.departments (
    department_id integer NOT NULL,
    department_code character varying(20) NOT NULL,
    department_name character varying(100) NOT NULL,
    description text,
    parent_department_id integer,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.departments OWNER TO myuser;

--
-- Name: departments_department_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.departments_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.departments_department_id_seq OWNER TO myuser;

--
-- Name: departments_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.departments_department_id_seq OWNED BY public.departments.department_id;


--
-- Name: manufacturers; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.manufacturers (
    manufacturer_id integer NOT NULL,
    manufacturer_code character varying(50) NOT NULL,
    manufacturer_name character varying(200) NOT NULL,
    website_url character varying(255),
    contact_email character varying(100),
    contact_phone character varying(30),
    address_line1 character varying(200),
    address_line2 character varying(200),
    city character varying(100),
    state_province character varying(100),
    postal_code character varying(20),
    country_code character varying(3),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.manufacturers OWNER TO myuser;

--
-- Name: manufacturers_manufacturer_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.manufacturers_manufacturer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.manufacturers_manufacturer_id_seq OWNER TO myuser;

--
-- Name: manufacturers_manufacturer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.manufacturers_manufacturer_id_seq OWNED BY public.manufacturers.manufacturer_id;


--
-- Name: product_attribute_values; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_attribute_values (
    value_id bigint NOT NULL,
    product_id bigint NOT NULL,
    attribute_id integer NOT NULL,
    value_text text,
    value_integer bigint,
    value_decimal double precision,
    value_boolean boolean,
    value_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_attribute_values OWNER TO myuser;

--
-- Name: TABLE product_attribute_values; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON TABLE public.product_attribute_values IS 'Flexible EAV (Entity-Attribute-Value) model for storing technical specifications';


--
-- Name: product_attribute_values_value_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_attribute_values_value_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_attribute_values_value_id_seq OWNER TO myuser;

--
-- Name: product_attribute_values_value_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_attribute_values_value_id_seq OWNED BY public.product_attribute_values.value_id;


--
-- Name: product_categories; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_categories (
    category_id integer NOT NULL,
    category_code character varying(50) NOT NULL,
    category_name character varying(100) NOT NULL,
    parent_category_id integer,
    category_level integer,
    department_id integer,
    description text,
    display_order integer,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_category_level CHECK (((category_level >= 1) AND (category_level <= 5)))
);


ALTER TABLE public.product_categories OWNER TO myuser;

--
-- Name: product_categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_categories_category_id_seq OWNER TO myuser;

--
-- Name: product_categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_categories_category_id_seq OWNED BY public.product_categories.category_id;


--
-- Name: product_category_assignments; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_category_assignments (
    assignment_id bigint NOT NULL,
    product_id bigint NOT NULL,
    category_id integer NOT NULL,
    assignment_type character varying(20) NOT NULL,
    display_order integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_category_assignments OWNER TO myuser;

--
-- Name: product_category_assignments_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_category_assignments_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_category_assignments_assignment_id_seq OWNER TO myuser;

--
-- Name: product_category_assignments_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_category_assignments_assignment_id_seq OWNED BY public.product_category_assignments.assignment_id;


--
-- Name: product_compatibility; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_compatibility (
    compatibility_id bigint NOT NULL,
    product_id bigint NOT NULL,
    compatible_with_product_id bigint,
    compatibility_type character varying(50),
    compatibility_notes text,
    is_verified boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_compatibility OWNER TO myuser;

--
-- Name: TABLE product_compatibility; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON TABLE public.product_compatibility IS 'Tracks product compatibility with other products';


--
-- Name: product_compatibility_compatibility_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_compatibility_compatibility_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_compatibility_compatibility_id_seq OWNER TO myuser;

--
-- Name: product_compatibility_compatibility_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_compatibility_compatibility_id_seq OWNED BY public.product_compatibility.compatibility_id;


--
-- Name: product_group_assignments; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_group_assignments (
    assignment_id bigint NOT NULL,
    product_id bigint NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_group_assignments OWNER TO myuser;

--
-- Name: product_group_assignments_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_group_assignments_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_group_assignments_assignment_id_seq OWNER TO myuser;

--
-- Name: product_group_assignments_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_group_assignments_assignment_id_seq OWNED BY public.product_group_assignments.assignment_id;


--
-- Name: product_groups; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_groups (
    group_id integer NOT NULL,
    group_code character varying(50) NOT NULL,
    group_name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_groups OWNER TO myuser;

--
-- Name: product_groups_group_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_groups_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_groups_group_id_seq OWNER TO myuser;

--
-- Name: product_groups_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_groups_group_id_seq OWNED BY public.product_groups.group_id;


--
-- Name: product_reference_codes; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_reference_codes (
    reference_id bigint NOT NULL,
    product_id bigint NOT NULL,
    code_type character varying(50) NOT NULL,
    reference_code character varying(100) NOT NULL,
    description character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_reference_codes OWNER TO myuser;

--
-- Name: TABLE product_reference_codes; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON TABLE public.product_reference_codes IS 'Legacy system identifiers and internal reference codes for products';


--
-- Name: product_reference_codes_reference_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_reference_codes_reference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_reference_codes_reference_id_seq OWNER TO myuser;

--
-- Name: product_reference_codes_reference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_reference_codes_reference_id_seq OWNED BY public.product_reference_codes.reference_id;


--
-- Name: product_relationship_types; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_relationship_types (
    relationship_type_id integer NOT NULL,
    type_code character varying(50) NOT NULL,
    type_name character varying(100) NOT NULL,
    description text,
    is_bidirectional boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_relationship_types OWNER TO myuser;

--
-- Name: product_relationship_types_relationship_type_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_relationship_types_relationship_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_relationship_types_relationship_type_id_seq OWNER TO myuser;

--
-- Name: product_relationship_types_relationship_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_relationship_types_relationship_type_id_seq OWNED BY public.product_relationship_types.relationship_type_id;


--
-- Name: product_relationships; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_relationships (
    relationship_id bigint NOT NULL,
    source_product_id bigint NOT NULL,
    related_product_id bigint NOT NULL,
    relationship_type_id integer NOT NULL,
    display_order integer,
    strength double precision,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT no_self_reference CHECK ((source_product_id <> related_product_id))
);


ALTER TABLE public.product_relationships OWNER TO myuser;

--
-- Name: TABLE product_relationships; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON TABLE public.product_relationships IS 'Defines relationships between products (cross-sell, upsell, substitutes, bundles, etc.)';


--
-- Name: COLUMN product_relationships.strength; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.product_relationships.strength IS 'Relationship strength (0.00-1.00) for ML-based recommendations';


--
-- Name: product_relationships_relationship_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_relationships_relationship_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_relationships_relationship_id_seq OWNER TO myuser;

--
-- Name: product_relationships_relationship_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_relationships_relationship_id_seq OWNED BY public.product_relationships.relationship_id;


--
-- Name: product_status; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_status (
    status_id integer NOT NULL,
    status_code character varying(20) NOT NULL,
    status_name character varying(50) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    display_order integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_status OWNER TO myuser;

--
-- Name: product_status_status_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_status_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_status_status_id_seq OWNER TO myuser;

--
-- Name: product_status_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_status_status_id_seq OWNED BY public.product_status.status_id;


--
-- Name: product_suppliers; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_suppliers (
    product_supplier_id bigint NOT NULL,
    product_id bigint NOT NULL,
    supplier_id integer NOT NULL,
    is_primary boolean DEFAULT false,
    supplier_product_code character varying(100),
    supplier_sku character varying(100),
    purchase_order_minimum integer,
    purchase_lead_time_days integer,
    supplier_cost double precision,
    supplier_currency character varying(3) DEFAULT 'USD'::character varying,
    last_purchase_date date,
    last_purchase_price double precision,
    is_preferred boolean DEFAULT false,
    notes text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_suppliers OWNER TO myuser;

--
-- Name: TABLE product_suppliers; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON TABLE public.product_suppliers IS 'Supplier relationships and procurement information for products';


--
-- Name: COLUMN product_suppliers.is_primary; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.product_suppliers.is_primary IS 'Indicates if this is the primary/preferred supplier for this product';


--
-- Name: COLUMN product_suppliers.purchase_lead_time_days; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.product_suppliers.purchase_lead_time_days IS 'Number of days from order to delivery';


--
-- Name: COLUMN product_suppliers.supplier_cost; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.product_suppliers.supplier_cost IS 'Cost per unit from this supplier';


--
-- Name: product_suppliers_product_supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_suppliers_product_supplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_suppliers_product_supplier_id_seq OWNER TO myuser;

--
-- Name: product_suppliers_product_supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_suppliers_product_supplier_id_seq OWNED BY public.product_suppliers.product_supplier_id;


--
-- Name: product_system_requirements; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_system_requirements (
    requirement_id bigint NOT NULL,
    product_id bigint NOT NULL,
    requirement_type character varying(50),
    operating_system character varying(200),
    processor character varying(200),
    memory_gb double precision,
    storage_gb double precision,
    graphics_card character varying(200),
    additional_requirements text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_system_requirements OWNER TO myuser;

--
-- Name: TABLE product_system_requirements; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON TABLE public.product_system_requirements IS 'Technical system requirements for products (software/hardware)';


--
-- Name: product_system_requirements_requirement_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_system_requirements_requirement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_system_requirements_requirement_id_seq OWNER TO myuser;

--
-- Name: product_system_requirements_requirement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_system_requirements_requirement_id_seq OWNED BY public.product_system_requirements.requirement_id;


--
-- Name: product_tag_assignments; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_tag_assignments (
    assignment_id bigint NOT NULL,
    product_id bigint NOT NULL,
    tag_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_tag_assignments OWNER TO myuser;

--
-- Name: product_tag_assignments_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_tag_assignments_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_tag_assignments_assignment_id_seq OWNER TO myuser;

--
-- Name: product_tag_assignments_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_tag_assignments_assignment_id_seq OWNED BY public.product_tag_assignments.assignment_id;


--
-- Name: product_tags; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.product_tags (
    tag_id integer NOT NULL,
    tag_name character varying(50) NOT NULL,
    tag_category character varying(50),
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_tags OWNER TO myuser;

--
-- Name: product_tags_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.product_tags_tag_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_tags_tag_id_seq OWNER TO myuser;

--
-- Name: product_tags_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.product_tags_tag_id_seq OWNED BY public.product_tags.tag_id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.products (
    product_id bigint NOT NULL,
    sku character varying(100) NOT NULL,
    upc character varying(20),
    ean character varying(20),
    gtin character varying(20),
    mpn character varying(100),
    asin character varying(20),
    product_name character varying(500) NOT NULL,
    short_description text,
    long_description text,
    brand_id integer,
    manufacturer_id integer,
    product_line character varying(100),
    product_series character varying(100),
    model_number character varying(100),
    status_id integer NOT NULL,
    launch_date date,
    discontinuation_date date,
    primary_category_id integer,
    department_id integer,
    length_value double precision,
    width_value double precision,
    height_value double precision,
    dimension_uom_id integer,
    weight_gross double precision,
    weight_net double precision,
    weight_uom_id integer,
    volume_value double precision,
    volume_uom_id integer,
    color_name character varying(50),
    color_code character varying(20),
    size_value character varying(50),
    material_composition text,
    packaging_type character varying(50),
    packaging_length double precision,
    packaging_width double precision,
    packaging_height double precision,
    packaging_weight double precision,
    packaging_uom_id integer,
    base_uom_id integer,
    units_per_package integer,
    units_per_case integer,
    units_per_pallet integer,
    parent_product_id bigint,
    is_variant boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.products OWNER TO myuser;

--
-- Name: TABLE products; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON TABLE public.products IS 'Core product master table containing essential product information and physical attributes';


--
-- Name: COLUMN products.sku; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.sku IS 'Unique Stock Keeping Unit identifier';


--
-- Name: COLUMN products.upc; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.upc IS 'Universal Product Code for retail scanning';


--
-- Name: COLUMN products.ean; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.ean IS 'European Article Number';


--
-- Name: COLUMN products.gtin; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.gtin IS 'Global Trade Item Number for international commerce';


--
-- Name: COLUMN products.mpn; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.mpn IS 'Manufacturer Part Number';


--
-- Name: COLUMN products.asin; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.asin IS 'Amazon Standard Identification Number for e-commerce';


--
-- Name: COLUMN products.short_description; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.short_description IS 'Brief product description for listings and previews';


--
-- Name: COLUMN products.long_description; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.long_description IS 'Detailed product description for product pages';


--
-- Name: COLUMN products.parent_product_id; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.parent_product_id IS 'Reference to parent product for variants (e.g., different colors/sizes of same product)';


--
-- Name: COLUMN products.is_variant; Type: COMMENT; Schema: public; Owner: myuser
--

COMMENT ON COLUMN public.products.is_variant IS 'Flag indicating if this product is a variant of a parent product';


--
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.products_product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.products_product_id_seq OWNER TO myuser;

--
-- Name: products_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.products_product_id_seq OWNED BY public.products.product_id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.suppliers (
    supplier_id integer NOT NULL,
    supplier_code character varying(50) NOT NULL,
    supplier_name character varying(200) NOT NULL,
    supplier_type character varying(30),
    contact_name character varying(100),
    contact_email character varying(100),
    contact_phone character varying(30),
    website_url character varying(255),
    address_line1 character varying(200),
    address_line2 character varying(200),
    city character varying(100),
    state_province character varying(100),
    postal_code character varying(20),
    country_code character varying(3),
    payment_terms character varying(50),
    tax_id character varying(50),
    is_preferred boolean DEFAULT false,
    is_active boolean DEFAULT true,
    rating double precision,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.suppliers OWNER TO myuser;

--
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.suppliers_supplier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.suppliers_supplier_id_seq OWNER TO myuser;

--
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.suppliers_supplier_id_seq OWNED BY public.suppliers.supplier_id;


--
-- Name: unit_of_measure; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.unit_of_measure (
    uom_id integer NOT NULL,
    uom_code character varying(10) NOT NULL,
    uom_name character varying(50) NOT NULL,
    uom_type character varying(20),
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.unit_of_measure OWNER TO myuser;

--
-- Name: unit_of_measure_uom_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.unit_of_measure_uom_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.unit_of_measure_uom_id_seq OWNER TO myuser;

--
-- Name: unit_of_measure_uom_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.unit_of_measure_uom_id_seq OWNED BY public.unit_of_measure.uom_id;


--
-- Name: attribute_options option_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attribute_options ALTER COLUMN option_id SET DEFAULT nextval('public.attribute_options_option_id_seq'::regclass);


--
-- Name: attribute_sets attribute_set_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attribute_sets ALTER COLUMN attribute_set_id SET DEFAULT nextval('public.attribute_sets_attribute_set_id_seq'::regclass);


--
-- Name: attributes attribute_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attributes ALTER COLUMN attribute_id SET DEFAULT nextval('public.attributes_attribute_id_seq'::regclass);


--
-- Name: brands brand_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.brands ALTER COLUMN brand_id SET DEFAULT nextval('public.brands_brand_id_seq'::regclass);


--
-- Name: departments department_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.departments ALTER COLUMN department_id SET DEFAULT nextval('public.departments_department_id_seq'::regclass);


--
-- Name: manufacturers manufacturer_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.manufacturers ALTER COLUMN manufacturer_id SET DEFAULT nextval('public.manufacturers_manufacturer_id_seq'::regclass);


--
-- Name: product_attribute_values value_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_attribute_values ALTER COLUMN value_id SET DEFAULT nextval('public.product_attribute_values_value_id_seq'::regclass);


--
-- Name: product_categories category_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_categories ALTER COLUMN category_id SET DEFAULT nextval('public.product_categories_category_id_seq'::regclass);


--
-- Name: product_category_assignments assignment_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_category_assignments ALTER COLUMN assignment_id SET DEFAULT nextval('public.product_category_assignments_assignment_id_seq'::regclass);


--
-- Name: product_compatibility compatibility_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_compatibility ALTER COLUMN compatibility_id SET DEFAULT nextval('public.product_compatibility_compatibility_id_seq'::regclass);


--
-- Name: product_group_assignments assignment_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_group_assignments ALTER COLUMN assignment_id SET DEFAULT nextval('public.product_group_assignments_assignment_id_seq'::regclass);


--
-- Name: product_groups group_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_groups ALTER COLUMN group_id SET DEFAULT nextval('public.product_groups_group_id_seq'::regclass);


--
-- Name: product_reference_codes reference_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_reference_codes ALTER COLUMN reference_id SET DEFAULT nextval('public.product_reference_codes_reference_id_seq'::regclass);


--
-- Name: product_relationship_types relationship_type_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_relationship_types ALTER COLUMN relationship_type_id SET DEFAULT nextval('public.product_relationship_types_relationship_type_id_seq'::regclass);


--
-- Name: product_relationships relationship_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_relationships ALTER COLUMN relationship_id SET DEFAULT nextval('public.product_relationships_relationship_id_seq'::regclass);


--
-- Name: product_status status_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_status ALTER COLUMN status_id SET DEFAULT nextval('public.product_status_status_id_seq'::regclass);


--
-- Name: product_suppliers product_supplier_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_suppliers ALTER COLUMN product_supplier_id SET DEFAULT nextval('public.product_suppliers_product_supplier_id_seq'::regclass);


--
-- Name: product_system_requirements requirement_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_system_requirements ALTER COLUMN requirement_id SET DEFAULT nextval('public.product_system_requirements_requirement_id_seq'::regclass);


--
-- Name: product_tag_assignments assignment_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_tag_assignments ALTER COLUMN assignment_id SET DEFAULT nextval('public.product_tag_assignments_assignment_id_seq'::regclass);


--
-- Name: product_tags tag_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_tags ALTER COLUMN tag_id SET DEFAULT nextval('public.product_tags_tag_id_seq'::regclass);


--
-- Name: products product_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products ALTER COLUMN product_id SET DEFAULT nextval('public.products_product_id_seq'::regclass);


--
-- Name: suppliers supplier_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN supplier_id SET DEFAULT nextval('public.suppliers_supplier_id_seq'::regclass);


--
-- Name: unit_of_measure uom_id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.unit_of_measure ALTER COLUMN uom_id SET DEFAULT nextval('public.unit_of_measure_uom_id_seq'::regclass);


--
-- Data for Name: attribute_options; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.attribute_options (option_id, attribute_id, option_value, option_label, display_order, is_default, is_active, created_at) FROM stdin;
1	7	2Z	Metal Shield (2Z)	1	f	t	2025-10-31 14:52:11.655933
2	7	2RS	Rubber Seal (2RS)	2	f	t	2025-10-31 14:52:11.655933
3	7	OPEN	Open	3	f	t	2025-10-31 14:52:11.655933
4	8	STEEL	Steel	1	t	t	2025-10-31 14:52:11.655933
5	8	BRASS	Brass	2	f	t	2025-10-31 14:52:11.655933
6	8	POLYAMIDE	Polyamide (PA66)	3	f	t	2025-10-31 14:52:11.655933
7	13	230/400	230/400V	1	t	t	2025-10-31 14:52:11.655933
8	13	460	460V	2	f	t	2025-10-31 14:52:11.655933
9	14	3-PHASE	3-Phase	1	t	t	2025-10-31 14:52:11.655933
10	14	1-PHASE	1-Phase	2	f	t	2025-10-31 14:52:11.655933
11	15	1	1 inch	1	f	t	2025-10-31 14:52:11.655933
12	15	1.25	1.25 inch	2	f	t	2025-10-31 14:52:11.655933
13	15	1.5	1.5 inch	3	f	t	2025-10-31 14:52:11.655933
18	15	2	2 inch	4	f	t	2025-11-03 10:01:50.91585
14	16	SS304	Stainless Steel 304	1	f	t	2025-10-31 14:52:11.655933
15	16	SS316	Stainless Steel 316	2	f	t	2025-10-31 14:52:11.655933
16	16	CAST-IRON	Cast Iron	3	f	t	2025-10-31 14:52:11.655933
19	23	IE3	IE3 Premium Efficiency	1	t	t	2025-11-03 10:01:50.91585
20	23	IE4	IE4 Super Premium Efficiency	2	f	t	2025-11-03 10:01:50.91585
21	23	IE2	IE2 High Efficiency	3	f	t	2025-11-03 10:01:50.91585
22	24	IEC80	IEC 80	1	f	t	2025-11-03 10:01:50.91585
23	24	IEC90	IEC 90	2	f	t	2025-11-03 10:01:50.91585
24	24	IEC100	IEC 100	3	f	t	2025-11-03 10:01:50.91585
25	24	IEC112	IEC 112	4	f	t	2025-11-03 10:01:50.91585
26	25	TEFC	Totally Enclosed Fan Cooled	1	t	t	2025-11-03 10:01:50.91585
27	25	ODP	Open Drip Proof	2	f	t	2025-11-03 10:01:50.91585
28	25	TENV	Totally Enclosed Non-Ventilated	3	f	t	2025-11-03 10:01:50.91585
29	28	SS316	Stainless Steel 316	1	t	t	2025-11-03 10:01:50.91585
30	28	BRASS	Brass	2	f	t	2025-11-03 10:01:50.91585
31	28	CARBON-STEEL	Carbon Steel	3	f	t	2025-11-03 10:01:50.91585
32	31	2-WAY	2-Way	1	t	t	2025-11-03 10:01:50.91585
33	31	3-WAY	3-Way	2	f	t	2025-11-03 10:01:50.91585
34	35	4-20MA	4-20mA	1	t	t	2025-11-03 10:01:50.91585
35	35	0-10V	0-10V	2	f	t	2025-11-03 10:01:50.91585
36	35	HART	HART Protocol	3	f	t	2025-11-03 10:01:50.91585
\.


--
-- Data for Name: attribute_sets; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.attribute_sets (attribute_set_id, set_code, set_name, description, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: attributes; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.attributes (attribute_id, attribute_code, attribute_name, attribute_type, data_type, unit_of_measure, is_filterable, is_searchable, is_comparable, validation_rules, display_order, is_active, created_at) FROM stdin;
1	BORE_DIA	Bore Diameter	number	decimal	mm	t	t	t	\N	1	t	2025-10-31 14:52:11.655933
2	OUTER_DIA	Outer Diameter	number	decimal	mm	t	t	t	\N	2	t	2025-10-31 14:52:11.655933
3	WIDTH	Width	number	decimal	mm	t	t	t	\N	3	t	2025-10-31 14:52:11.655933
4	DYNAMIC_LOAD	Dynamic Load Rating	number	decimal	kN	t	f	t	\N	4	t	2025-10-31 14:52:11.655933
5	STATIC_LOAD	Static Load Rating	number	decimal	kN	t	f	t	\N	5	t	2025-10-31 14:52:11.655933
6	MAX_SPEED	Maximum Speed	number	integer	RPM	t	f	t	\N	6	t	2025-10-31 14:52:11.655933
7	SEAL_TYPE	Seal Type	select	string	\N	t	t	t	\N	7	t	2025-10-31 14:52:11.655933
8	CAGE_MATERIAL	Cage Material	select	string	\N	t	t	t	\N	8	t	2025-10-31 14:52:11.655933
9	FLOW_RATE	Maximum Flow Rate	number	decimal	m³/h	t	t	t	\N	1	t	2025-10-31 14:52:11.655933
10	HEAD_MAX	Maximum Head	number	decimal	m	t	t	t	\N	2	t	2025-10-31 14:52:11.655933
11	MOTOR_POWER	Motor Power	number	decimal	kW	t	t	t	\N	3	t	2025-10-31 14:52:11.655933
12	NUM_STAGES	Number of Stages	number	integer	\N	t	t	t	\N	4	t	2025-10-31 14:52:11.655933
13	VOLTAGE	Voltage	select	string	V	t	t	t	\N	5	t	2025-10-31 14:52:11.655933
14	PHASE	Phase	select	string	\N	t	t	t	\N	6	t	2025-10-31 14:52:11.655933
15	CONNECTION_SIZE	Connection Size	select	string	inch	t	t	t	\N	7	t	2025-10-31 14:52:11.655933
16	MATERIAL_IMPELLER	Impeller Material	select	string	\N	t	t	t	\N	8	t	2025-10-31 14:52:11.655933
17	TEMP_MAX	Maximum Temperature	number	integer	°C	t	f	t	\N	9	t	2025-10-31 14:52:11.655933
18	PRESSURE_MAX	Maximum Pressure	number	decimal	bar	t	f	t	\N	10	t	2025-10-31 14:52:11.655933
19	RATED_POWER	Rated Power	number	decimal	kW	t	t	t	\N	1	t	2025-11-03 10:01:50.91585
20	RATED_VOLTAGE	Rated Voltage	select	string	V	t	t	t	\N	2	t	2025-11-03 10:01:50.91585
21	RATED_CURRENT	Rated Current	number	decimal	A	t	f	t	\N	3	t	2025-11-03 10:01:50.91585
22	MOTOR_SPEED	Rated Speed	number	integer	RPM	t	t	t	\N	4	t	2025-11-03 10:01:50.91585
23	MOTOR_EFF	Efficiency Class	select	string	\N	t	t	t	\N	5	t	2025-11-03 10:01:50.91585
24	FRAME_SIZE	Frame Size	select	string	\N	t	t	t	\N	6	t	2025-11-03 10:01:50.91585
25	ENCLOSURE	Enclosure Type	select	string	\N	t	t	t	\N	7	t	2025-11-03 10:01:50.91585
26	INSULATION	Insulation Class	select	string	\N	t	f	t	\N	8	t	2025-11-03 10:01:50.91585
27	VALVE_SIZE	Valve Size	select	string	inch	t	t	t	\N	1	t	2025-11-03 10:01:50.91585
28	VALVE_MATERIAL	Body Material	select	string	\N	t	t	t	\N	2	t	2025-11-03 10:01:50.91585
29	PRESSURE_RATING	Pressure Rating	number	integer	psi	t	t	t	\N	3	t	2025-11-03 10:01:50.91585
30	TEMP_RATING	Temperature Rating	number	integer	°C	t	f	t	\N	4	t	2025-11-03 10:01:50.91585
31	PORT_CONFIG	Port Configuration	select	string	\N	t	t	t	\N	5	t	2025-11-03 10:01:50.91585
32	ACTUATOR_TYPE	Actuator Type	select	string	\N	t	t	t	\N	6	t	2025-11-03 10:01:50.91585
33	PRESS_RANGE	Pressure Range	text	string	bar	t	t	t	\N	1	t	2025-11-03 10:01:50.91585
34	ACCURACY	Accuracy	text	string	%	t	t	t	\N	2	t	2025-11-03 10:01:50.91585
35	OUTPUT_SIGNAL	Output Signal	select	string	\N	t	t	t	\N	3	t	2025-11-03 10:01:50.91585
36	PROCESS_CONN	Process Connection	select	string	\N	t	t	t	\N	4	t	2025-11-03 10:01:50.91585
37	DISPLAY_TYPE	Display Type	select	string	\N	t	f	t	\N	5	t	2025-11-03 10:01:50.91585
\.


--
-- Data for Name: brands; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.brands (brand_id, brand_code, brand_name, brand_logo_url, website_url, description, is_active, created_at, updated_at) FROM stdin;
1	ABC-COFFEE	ABC Coffee Components	https://www.abc-coffee.com/logo.png	https://www.abc-coffee.com	ABC Coffee Components designs and manufactures valves, sensors, brew modules, and service parts for commercial coffee machines	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	GRUNDFOS	Grundfos	https://www.grundfos.com/logo.png	https://www.grundfos.com	Grundfos is a global leader in advanced pump solutions and water technology	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
3	SIEMENS	Siemens	https://www.siemens.com/logo.png	https://www.siemens.com	Siemens is a global technology powerhouse focusing on electrification, automation and digitalization	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
4	ABB	ABB	https://www.abb.com/logo.png	https://www.abb.com	ABB is a technology leader in electrification and automation	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
5	TIMKEN	Timken	https://www.timken.com/logo.png	https://www.timken.com	The Timken Company designs and manufactures bearings and power transmission products	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
6	NSK	NSK	https://www.nsk.com/logo.png	https://www.nsk.com	NSK manufactures bearings and precision machinery	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
7	SWAGELOK	Swagelok	https://www.swagelok.com/logo.png	https://www.swagelok.com	Swagelok Company delivers fluid system solutions	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
8	EMERSON	Emerson	https://www.emerson.com/logo.png	https://www.emerson.com	Emerson is a global technology and engineering company	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
9	SCHNEIDER	Schneider Electric	https://www.se.com/logo.png	https://www.se.com	Schneider Electric is a leader in energy management and automation	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
10	ENDRESS	Endress+Hauser	https://www.endress.com/logo.png	https://www.endress.com	Endress+Hauser is a global leader in measurement instrumentation	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
11	PARKER	Parker Hannifin	https://www.parker.com/logo.png	https://www.parker.com	Parker Hannifin is a leader in motion and control technologies	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
12	FESTO	Festo	https://www.festo.com/logo.png	https://www.festo.com	Festo is a leading supplier of pneumatic and electrical automation technology	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
13	EATON	Eaton	https://www.eaton.com/logo.png	https://www.eaton.com	Eaton is a power management company	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
14	ROSEMOUNT	Rosemount	https://www.rosemount.com/logo.png	https://www.rosemount.com	Rosemount is a leading brand for process measurement and control	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
15	DANFOSS	Danfoss	https://www.danfoss.com/logo.png	https://www.danfoss.com	Danfoss engineers solutions for energy efficient heating, cooling, and drives	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.departments (department_id, department_code, department_name, description, parent_department_id, is_active, created_at, updated_at) FROM stdin;
1	IND-COMP	Industrial Components	Industrial machinery components and parts	\N	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	FLUID-SYS	Fluid Systems	Pumps, valves, and fluid handling equipment	\N	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
3	ELEC-SYS	Electrical Systems	Motors, drives, and electrical components	\N	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
4	AUTO-CTRL	Automation & Control	Sensors, controllers, and automation equipment	\N	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
5	PNEUM-HYD	Pneumatics & Hydraulics	Pneumatic and hydraulic components	\N	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
\.


--
-- Data for Name: manufacturers; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.manufacturers (manufacturer_id, manufacturer_code, manufacturer_name, website_url, contact_email, contact_phone, address_line1, address_line2, city, state_province, postal_code, country_code, is_active, created_at, updated_at) FROM stdin;
1	ABC-COFFEE-FR	ABC Coffee Components SAS	https://www.abc-coffee.com	support@abc-coffee.com	+33-4-78-88-42-10	18 Rue des Torréfacteurs	\N	Lyon	Auvergne-Rhône-Alpes	69007	FRA	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	GRUNDFOS-DK	Grundfos Holding A/S	https://www.grundfos.com	info@grundfos.com	+45-87-50-1400	Poul Due Jensens Vej 7	\N	Bjerringbro	Central Jutland	8850	DNK	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
3	SIEMENS-DE	Siemens AG	https://www.siemens.com	info@siemens.com	+49-89-636-00	Werner-von-Siemens-Straße 1	\N	Munich	Bavaria	80333	DEU	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
4	ABB-CH	ABB Ltd	https://www.abb.com	contact@abb.com	+41-43-317-7111	Affolternstrasse 44	\N	Zurich	Zurich	8050	CHE	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
5	TIMKEN-US	The Timken Company	https://www.timken.com	info@timken.com	+1-330-438-3000	4500 Mount Pleasant Street NW	\N	Canton	Ohio	44718	USA	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
6	NSK-JP	NSK Ltd.	https://www.nsk.com	contact@nsk.com	+81-3-3779-7111	1-5-50 Kudan-Minami	\N	Tokyo	Chiyoda-ku	102-8450	JPN	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
7	SWAGELOK-US	Swagelok Company	https://www.swagelok.com	info@swagelok.com	+1-440-248-4600	29500 Solon Road	\N	Solon	Ohio	44139	USA	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
8	EMERSON-US	Emerson Electric Co.	https://www.emerson.com	info@emerson.com	+1-314-553-2000	8000 West Florissant Avenue	\N	St. Louis	Missouri	63136	USA	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
9	SCHNEIDER-FR	Schneider Electric SE	https://www.se.com	contact@se.com	+33-1-41-29-70-00	35 rue Joseph Monier	\N	Rueil-Malmaison	Île-de-France	92500	FRA	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
10	ENDRESS-CH	Endress+Hauser AG	https://www.endress.com	info@endress.com	+41-61-715-7575	Kägenstrasse 2	\N	Reinach	Basel-Landschaft	4153	CHE	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
11	PARKER-US	Parker Hannifin Corporation	https://www.parker.com	info@parker.com	+1-216-896-3000	6035 Parkland Boulevard	\N	Cleveland	Ohio	44124	USA	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
12	FESTO-DE	Festo SE & Co. KG	https://www.festo.com	info@festo.com	+49-711-347-0	Ruiter Straße 82	\N	Esslingen	Baden-Württemberg	73734	DEU	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
13	EATON-IE	Eaton Corporation plc	https://www.eaton.com	info@eaton.com	+353-1-637-2900	Beech Hill Office Campus	\N	Dublin	Leinster	D04 XV32	IRL	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
14	EMERSON-US-2	Emerson Electric Co. (Rosemount)	https://www.emerson.com	rosemount@emerson.com	+1-952-906-8888	8200 Market Boulevard	\N	Chanhassen	Minnesota	55317	USA	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
15	DANFOSS-DK	Danfoss A/S	https://www.danfoss.com	info@danfoss.com	+45-74-88-2222	Nordborgvej 81	\N	Nordborg	Southern Denmark	6430	DNK	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
\.


--
-- Data for Name: product_attribute_values; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_attribute_values (value_id, product_id, attribute_id, value_text, value_integer, value_decimal, value_boolean, value_date, created_at, updated_at) FROM stdin;
1	1	1	\N	\N	25	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	1	2	\N	\N	52	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
3	1	3	\N	\N	15	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
4	1	4	\N	\N	10.8	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
5	1	5	\N	\N	6.65	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
6	1	6	\N	17000	\N	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
7	1	7	2Z	\N	\N	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
8	1	8	STEEL	\N	\N	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
9	2	9	\N	\N	5.5	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
10	2	10	\N	\N	72	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
11	2	11	\N	\N	3	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
12	2	12	\N	8	\N	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
13	2	13	230/400	\N	\N	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
14	2	14	3-PHASE	\N	\N	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
15	2	15	1.5	\N	\N	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
16	2	16	SS304	\N	\N	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
17	2	17	\N	120	\N	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
18	2	18	\N	\N	20	\N	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
263	12	1	\N	\N	17	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
264	12	2	\N	\N	40	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
265	12	3	\N	\N	12	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
266	12	6	\N	\N	9500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
267	12	7	\N	\N	4750	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
268	12	4	\N	\N	18000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
269	12	8	Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
270	12	10	Metal Shield (Both Sides)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
271	12	11	Standard (CN)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
272	13	1	\N	\N	35	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
273	13	2	\N	\N	72	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
274	13	3	\N	\N	17	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
275	13	6	\N	\N	25500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
276	13	7	\N	\N	13700	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
277	13	4	\N	\N	11000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
278	13	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
279	13	10	Metal Shield (Both Sides)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
280	14	1	\N	\N	40	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
281	14	2	\N	\N	80	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
282	14	3	\N	\N	18	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
283	14	6	\N	\N	32000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
284	14	7	\N	\N	17600	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
285	14	4	\N	\N	9500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
286	14	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
287	14	10	Rubber Seal (Both Sides)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
288	14	9	Grease Lubrication	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
289	15	1	\N	\N	25	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
290	15	2	\N	\N	52	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
291	15	3	\N	\N	15	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
292	15	6	\N	\N	14000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
293	15	7	\N	\N	7800	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
294	15	4	\N	\N	15000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
295	15	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
296	15	10	Metal Shield (Both Sides)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
297	15	11	C3 (Greater than Normal)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
298	16	1	\N	\N	30	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
299	16	2	\N	\N	62	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
300	16	3	\N	\N	16	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
301	16	6	\N	\N	19500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
302	16	7	\N	\N	11200	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
303	16	4	\N	\N	12000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
304	16	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
305	16	10	Rubber Seal (Both Sides)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
306	16	11	C3 (Greater than Normal)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
307	17	1	\N	\N	20	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
308	17	2	\N	\N	47	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
309	17	3	\N	\N	15.25	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
310	17	6	\N	\N	12800	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
311	17	7	\N	\N	10200	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
312	17	4	\N	\N	10000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
313	17	8	Alloy Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
314	18	1	\N	\N	35	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
315	18	2	\N	\N	72	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
316	18	3	\N	\N	18.25	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
317	18	6	\N	\N	31800	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
318	18	7	\N	\N	26500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
319	18	4	\N	\N	6700	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
320	18	8	Alloy Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
321	19	1	\N	\N	40	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
322	19	2	\N	\N	80	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
323	19	3	\N	\N	24.75	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
324	19	6	\N	\N	48000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
325	19	7	\N	\N	42500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
326	19	4	\N	\N	6300	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
327	19	8	Premium Alloy Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
328	29	19	\N	\N	1.1	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
329	29	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
330	29	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
331	29	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
332	29	24	IE2	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
333	29	31	\N	\N	4.5	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
334	29	32	\N	\N	28	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
335	29	33	\N	4	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
336	29	34	\N	\N	10	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
337	30	19	\N	\N	2.2	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
338	30	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
339	30	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
340	30	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
341	30	24	IE3	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
342	30	31	\N	\N	3	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
343	30	32	\N	\N	58	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
344	30	33	\N	8	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
345	30	34	\N	\N	16	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
346	31	19	\N	\N	5.5	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
347	31	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
348	31	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
349	31	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
350	31	24	IE3	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
351	31	31	\N	\N	10	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
352	31	32	\N	\N	43	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
353	31	33	\N	6	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
354	31	34	\N	\N	16	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
355	32	19	\N	\N	2.2	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
356	32	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
357	32	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
358	32	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
359	32	24	IE5	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
360	32	31	\N	\N	5	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
361	32	32	\N	\N	29	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
362	32	33	\N	4	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
363	32	34	\N	\N	16	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
364	33	19	\N	\N	0.75	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
365	33	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
366	33	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
367	33	22	\N	\N	50	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
368	33	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
369	33	24	IE2	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
370	33	25	B3 (Foot Mounted)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
371	33	26	Cast Iron	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
372	34	19	\N	\N	1.1	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
373	34	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
374	34	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
375	34	22	\N	\N	50	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
376	34	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
377	34	24	IE3	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
378	34	25	B3 (Foot Mounted)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
379	34	26	Aluminum	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
380	35	19	\N	\N	2.2	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
381	35	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
382	35	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
383	35	22	\N	\N	50	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
384	35	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
385	35	24	IE3	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
386	35	25	B3 (Foot Mounted)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
387	35	26	Aluminum	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
388	36	19	\N	\N	1.5	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
389	36	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
390	36	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
391	36	22	\N	\N	50	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
392	36	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
393	36	24	IE4	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
394	36	25	B3 (Foot Mounted)	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
395	36	26	Aluminum	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
396	37	19	\N	\N	0.75	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
397	37	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
398	37	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
399	37	22	\N	\N	50	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
400	37	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
401	37	24	IE3	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
402	37	26	Aluminum	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
403	38	19	\N	\N	1.5	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
404	38	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
405	38	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
406	38	22	\N	\N	50	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
407	38	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
408	38	24	IE3	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
409	38	26	Aluminum	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
410	39	19	\N	\N	2.2	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
411	39	20	3-phase	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
412	39	21	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
413	39	22	\N	\N	50	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
414	39	23	\N	\N	1500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
415	39	24	IE4	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
416	39	26	Aluminum	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
417	40	19	\N	\N	0.75	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
418	40	28	\N	\N	37	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
419	40	29	\N	\N	190	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
420	40	30	\N	\N	41	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
421	41	19	\N	\N	1.5	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
422	41	28	\N	\N	47	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
423	41	29	\N	\N	380	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
424	41	30	\N	\N	32	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
425	42	19	\N	\N	0.75	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
426	42	28	\N	\N	37	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
427	42	29	\N	\N	185	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
428	42	30	\N	\N	41	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
429	43	28	\N	\N	40	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
430	43	29	\N	\N	400	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
431	43	27	\N	2	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
432	44	28	\N	\N	63	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
433	44	29	\N	\N	850	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
434	44	27	\N	3	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
435	45	28	\N	\N	82	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
436	45	29	\N	\N	18000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
437	45	27	\N	13	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
438	46	28	\N	\N	25	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
439	46	29	\N	\N	1200	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
440	46	27	\N	6	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
441	47	28	\N	\N	40	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
442	47	29	\N	\N	2500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
443	47	27	\N	8	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
444	8	1	\N	\N	25	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
445	8	2	\N	\N	52	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
446	8	3	\N	\N	15	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
447	8	6	\N	\N	14600	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
448	8	7	\N	\N	8800	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
449	8	4	\N	\N	15000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
450	8	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
451	21	1	\N	\N	30	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
452	21	2	\N	\N	62	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
453	21	3	\N	\N	16	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
454	21	6	\N	\N	20300	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
455	21	7	\N	\N	12700	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
456	21	4	\N	\N	12000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
457	21	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
458	22	1	\N	\N	40	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
459	22	2	\N	\N	80	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
460	22	3	\N	\N	18	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
461	22	6	\N	\N	33200	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
462	22	7	\N	\N	22000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
463	22	4	\N	\N	9500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
464	22	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
465	23	1	\N	\N	20	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
466	23	2	\N	\N	47	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
467	23	3	\N	\N	14	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
468	23	6	\N	\N	13500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
469	23	7	\N	\N	9800	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
470	23	4	\N	\N	16000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
471	23	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
472	24	1	\N	\N	30	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
473	24	2	\N	\N	62	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
474	24	3	\N	\N	16	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
475	24	6	\N	\N	25800	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
476	24	7	\N	\N	19600	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
477	24	4	\N	\N	11000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
478	24	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
479	25	1	\N	\N	40	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
480	25	2	\N	\N	80	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
481	25	3	\N	\N	18	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
482	25	6	\N	\N	40500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
483	25	7	\N	\N	33500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
484	25	4	\N	\N	9000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
485	25	8	Premium Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
486	26	1	\N	\N	25	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
487	26	2	\N	\N	52	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
488	26	3	\N	\N	15	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
489	26	6	\N	\N	7800	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
490	26	7	\N	\N	5000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
491	26	4	\N	\N	14000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
492	26	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
493	27	1	\N	\N	30	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
494	27	2	\N	\N	62	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
495	27	3	\N	\N	16	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
496	27	6	\N	\N	10600	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
497	27	7	\N	\N	6950	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
498	27	4	\N	\N	11000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
499	27	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
500	28	1	\N	\N	40	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
501	28	2	\N	\N	80	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
502	28	3	\N	\N	18	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
503	28	6	\N	\N	17000	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
504	28	7	\N	\N	11800	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
505	28	4	\N	\N	8500	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
506	28	8	Chrome Steel	\N	\N	\N	\N	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
\.


--
-- Data for Name: product_categories; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_categories (category_id, category_code, category_name, parent_category_id, category_level, department_id, description, display_order, is_active, created_at, updated_at) FROM stdin;
1	POWER-TRANS	Power Transmission	\N	1	1	Components that transmit mechanical power	1	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	PUMPS	Pumps & Pumping Equipment	\N	1	2	Equipment for moving fluids	1	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
9	MOTORS	Motors & Drives	\N	1	3	Electric motors and variable frequency drives	2	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
10	VALVES	Valves & Actuators	\N	1	2	Flow control devices	3	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
11	SENSORS	Sensors & Instrumentation	\N	1	4	Measurement and sensing devices	4	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
12	PNEUMATICS	Pneumatic Components	\N	1	5	Compressed air system components	5	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
3	BEARINGS	Bearings	1	2	1	Rolling element bearings for rotational applications	1	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
4	CENTRIFUGAL	Centrifugal Pumps	2	2	2	Pumps using rotational energy to move fluids	1	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
13	AC-MOTORS	AC Motors	9	2	3	Alternating current electric motors	1	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
14	VFD	Variable Frequency Drives	9	2	3	Motor speed controllers	2	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
15	BALL-VALVES	Ball Valves	10	2	2	Quarter-turn rotary valves	1	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
16	PRESSURE-SENS	Pressure Sensors	11	2	4	Pressure measurement devices	1	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
17	CYLINDERS	Pneumatic Cylinders	12	2	5	Linear actuators	1	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
18	GEARBOXES	Gearboxes & Reducers	1	2	1	Speed reduction and torque multiplication	2	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
5	BALL-BEAR	Ball Bearings	3	3	1	Bearings using balls as rolling elements	1	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
6	MULTI-STAGE	Multi-Stage Centrifugal Pumps	4	3	2	Multi-stage centrifugal pumps for high pressure	1	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
19	ROLLER-BEAR	Roller Bearings	3	3	1	Bearings using rollers as rolling elements	2	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
20	INDUCTION	Induction Motors	13	3	3	AC induction motors	1	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
21	SERVO	Servo Motors	13	3	3	Precision servo motors	2	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
7	DEEP-GROOVE	Deep Groove Ball Bearings	5	4	1	General purpose deep groove ball bearings	1	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
8	VERT-MULTI	Vertical Multi-Stage Pumps	6	4	2	Vertical orientation multi-stage pumps	1	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
22	ANGULAR-CONTACT	Angular Contact Ball Bearings	5	4	1	Bearings designed for combined loads	2	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
23	TAPERED-ROLLER	Tapered Roller Bearings	19	4	1	Cone-shaped roller bearings	1	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
\.


--
-- Data for Name: product_category_assignments; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_category_assignments (assignment_id, product_id, category_id, assignment_type, display_order, created_at) FROM stdin;
1	1	3	secondary	1	2025-10-31 14:52:11.655933
2	1	1	tertiary	2	2025-10-31 14:52:11.655933
3	2	4	secondary	1	2025-10-31 14:52:11.655933
4	2	2	tertiary	2	2025-10-31 14:52:11.655933
5	12	16	secondary	1	2025-11-03 11:05:46.341181
6	13	17	secondary	1	2025-11-03 11:05:46.341181
7	14	17	secondary	1	2025-11-03 11:05:46.341181
8	18	18	secondary	1	2025-11-03 11:05:46.341181
9	19	18	secondary	1	2025-11-03 11:05:46.341181
10	33	19	secondary	1	2025-11-03 11:05:46.341181
11	34	17	secondary	1	2025-11-03 11:05:46.341181
12	35	17	secondary	1	2025-11-03 11:05:46.341181
13	37	19	secondary	1	2025-11-03 11:05:46.341181
14	59	20	secondary	1	2025-11-03 11:05:46.341181
15	60	20	secondary	1	2025-11-03 11:05:46.341181
16	29	19	secondary	1	2025-11-03 11:05:46.341181
17	30	19	secondary	1	2025-11-03 11:05:46.341181
18	31	17	secondary	1	2025-11-03 11:05:46.341181
19	57	19	secondary	1	2025-11-03 11:05:46.341181
20	58	19	secondary	1	2025-11-03 11:05:46.341181
\.


--
-- Data for Name: product_compatibility; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_compatibility (compatibility_id, product_id, compatible_with_product_id, compatibility_type, compatibility_notes, is_verified, created_at, updated_at) FROM stdin;
1	1	2	hardware	Bearing 6205-2Z is used in Grundfos CR5-8 motor assembly	t	2025-10-31 14:52:11.655933	2025-11-03 11:04:16.706302
27	1	9	Component	ABC Coffee 6204 sealed cartridge suitable for CR3-6 auxiliary pump motor end	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
28	3	10	Component	ABC Coffee 6205 brew pump cartridge standard for CR5-8 pump shaft	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
29	4	10	Component	ABC Coffee 6206 grinder motor cartridge compatible with CR5-8 pump drive end	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
30	4	31	Component	ABC Coffee 6206 grinder motor cartridge fits CR10-6 pump motor bearing positions	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
31	13	31	Component	ABC Coffee 6207 steam pump shaft cartridge for CR10-6 pump support	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
32	15	10	Component	ABC Coffee 6205 high-temp brew group cartridge for CR5-8 hot water applications	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
33	1	33	Component	ABC Coffee 6204 sealed cartridge front bearing for M2QA 90S motor	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
34	7	33	Component	NSK 7205B angular contact optional upgrade for M2QA 90S	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
35	3	34	Component	ABC Coffee 6205 brew pump cartridge standard for M3BP 90S drive end	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
36	8	34	Component	NSK 7205B performance upgrade for M3BP 90S	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
37	4	35	Component	ABC Coffee 6206 grinder motor cartridge fits M3BP 100L motor bearings	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
38	21	35	Component	NSK 7206B high-performance option for M3BP 100L	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
39	7	37	Component	NSK 7205B compatible with 1LE1001 motor	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
40	8	38	Component	NSK 7205B fits 1LE1002 bearing positions	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
41	21	39	Component	NSK 7206B suitable for 1LE1501 motor	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
42	33	43	Drive System	ABB M2QA 90S mates with NORD SK 02040.1 via standard IEC flange	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
43	34	43	Drive System	ABB M3BP 90S compatible with NORD SK 02040.1 gearbox	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
44	34	44	Drive System	ABB M3BP 90S fits NORD SK 03063.1 with adapter	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
45	35	44	Drive System	ABB M3BP 100L direct mount to NORD SK 03063.1	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
46	35	46	Drive System	ABB M3BP 100L compatible with Flender B3SH06	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
47	38	44	Drive System	Siemens 1LE1002 mates with NORD SK 03063.1	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
48	39	46	Drive System	Siemens 1LE1501 direct coupling to Flender B3SH06	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
49	39	47	Drive System	Siemens 1LE1501 compatible with Flender B3SH08	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
50	40	57	Drive System	SEW R37 can drive TP32-120/2 pump via coupling	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
51	41	58	Drive System	SEW R47 suitable for driving TP40-180/2 pump	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
\.


--
-- Data for Name: product_group_assignments; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_group_assignments (assignment_id, product_id, group_id, created_at) FROM stdin;
1	1	1	2025-10-31 14:52:11.655933
2	1	3	2025-10-31 14:52:11.655933
3	2	2	2025-10-31 14:52:11.655933
4	2	3	2025-10-31 14:52:11.655933
5	12	1	2025-11-03 11:05:46.341181
6	13	1	2025-11-03 11:05:46.341181
7	14	1	2025-11-03 11:05:46.341181
8	15	1	2025-11-03 11:05:46.341181
9	16	1	2025-11-03 11:05:46.341181
10	17	1	2025-11-03 11:05:46.341181
11	18	1	2025-11-03 11:05:46.341181
12	19	1	2025-11-03 11:05:46.341181
13	8	1	2025-11-03 11:05:46.341181
14	21	1	2025-11-03 11:05:46.341181
15	22	1	2025-11-03 11:05:46.341181
16	23	1	2025-11-03 11:05:46.341181
17	24	1	2025-11-03 11:05:46.341181
18	25	1	2025-11-03 11:05:46.341181
19	26	1	2025-11-03 11:05:46.341181
20	27	1	2025-11-03 11:05:46.341181
21	28	1	2025-11-03 11:05:46.341181
22	48	1	2025-11-03 11:05:46.341181
23	49	1	2025-11-03 11:05:46.341181
24	50	1	2025-11-03 11:05:46.341181
25	51	1	2025-11-03 11:05:46.341181
26	52	1	2025-11-03 11:05:46.341181
27	53	1	2025-11-03 11:05:46.341181
28	54	1	2025-11-03 11:05:46.341181
29	55	1	2025-11-03 11:05:46.341181
30	56	1	2025-11-03 11:05:46.341181
31	32	2	2025-11-03 11:05:46.341181
32	34	2	2025-11-03 11:05:46.341181
33	35	2	2025-11-03 11:05:46.341181
34	36	2	2025-11-03 11:05:46.341181
35	37	2	2025-11-03 11:05:46.341181
36	38	2	2025-11-03 11:05:46.341181
37	39	2	2025-11-03 11:05:46.341181
38	29	3	2025-11-03 11:05:46.341181
39	30	3	2025-11-03 11:05:46.341181
40	31	3	2025-11-03 11:05:46.341181
41	32	3	2025-11-03 11:05:46.341181
\.


--
-- Data for Name: product_groups; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_groups (group_id, group_code, group_name, description, is_active, created_at, updated_at) FROM stdin;
1	MAINT-STOCK	Maintenance Stock Items	High-turnover items for maintenance and repair	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	SPEC-ORDER	Special Order Items	Made-to-order or low-turnover specialty items	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
3	CRITICAL	Critical Spare Parts	Mission-critical components requiring immediate availability	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
4	ENERGY-SAVE	Energy Saving Products	Products designed for energy efficiency	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
5	HAZLOC	Hazardous Location Rated	Products certified for hazardous environments	t	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
\.


--
-- Data for Name: product_reference_codes; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_reference_codes (reference_id, product_id, code_type, reference_code, description, created_at) FROM stdin;
1	1	legacy_sap	MAT-100234567	Legacy SAP material number	2025-10-31 14:52:11.655933
2	1	internal	CFE-ABC-001	Internal coffee machine spare parts catalog reference	2025-10-31 14:52:11.655933
3	1	supplier_motion	MOT-6205Z	Motion Industries product code	2025-10-31 14:52:11.655933
4	2	legacy_sap	MAT-200345678	Legacy SAP material number	2025-10-31 14:52:11.655933
5	2	internal	PMP-GRU-CR5-001	Internal pump catalog reference	2025-10-31 14:52:11.655933
6	2	supplier_grainger	GRA-4RKL8	Grainger product code	2025-10-31 14:52:11.655933
\.


--
-- Data for Name: product_relationship_types; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_relationship_types (relationship_type_id, type_code, type_name, description, is_bidirectional, is_active, created_at) FROM stdin;
1	RELATED	Related Product	\N	t	t	2025-10-31 14:51:39.008812
2	CROSS_SELL	Cross-Sell	\N	f	t	2025-10-31 14:51:39.008812
3	UP_SELL	Up-Sell	\N	f	t	2025-10-31 14:51:39.008812
4	SUBSTITUTE	Substitute/Alternative	\N	t	t	2025-10-31 14:51:39.008812
5	ACCESSORY	Accessory/Complementary	\N	f	t	2025-10-31 14:51:39.008812
6	BUNDLE_COMPONENT	Bundle Component	\N	f	t	2025-10-31 14:51:39.008812
7	REPLACEMENT_PART	Replacement Part	\N	f	t	2025-10-31 14:51:39.008812
8	PREDECESSOR	Predecessor	\N	f	t	2025-10-31 14:51:39.008812
9	SUCCESSOR	Successor	\N	f	t	2025-10-31 14:51:39.008812
10	COMPATIBLE_WITH	Compatible With	\N	t	t	2025-10-31 14:51:39.008812
11	UPSELL	Up-Sell	Suggests a higher-value or premium alternative product	f	t	2025-11-03 11:05:46.341181
\.


--
-- Data for Name: product_relationships; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_relationships (relationship_id, source_product_id, related_product_id, relationship_type_id, display_order, strength, is_active, created_at, updated_at) FROM stdin;
1	2	1	10	1	0.95	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	2	1	5	2	0.85	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
3	1	2	2	1	0.75	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
653	23	24	11	1	0.89	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
654	23	25	11	2	0.8	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
655	24	25	11	1	0.85	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
656	24	52	11	2	0.83	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
657	53	54	11	1	0.87	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
658	8	21	11	1	0.9	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
659	8	22	11	2	0.82	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
660	21	22	11	1	0.88	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
661	26	27	11	1	0.91	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
662	26	28	11	2	0.83	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
663	27	28	11	1	0.87	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
664	55	56	11	1	0.86	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
665	48	49	11	1	0.88	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
666	3	1	11	1	0.9	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
667	1	13	11	2	0.87	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
668	1	15	11	3	0.78	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
669	50	51	11	1	0.88	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
670	43	45	11	2	0.75	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
671	40	42	11	2	0.78	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
672	59	60	11	1	0.89	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
673	33	36	11	2	0.88	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
674	33	37	11	3	0.7	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
675	35	36	11	3	0.85	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
676	37	39	11	2	0.85	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
677	38	36	11	3	0.72	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
678	29	30	11	2	0.85	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
679	29	2	11	3	0.82	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
680	30	2	11	1	0.92	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
681	30	32	11	2	0.89	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
682	2	31	11	1	0.85	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
683	2	32	11	2	0.92	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
684	57	58	11	1	0.88	t	2025-11-03 12:40:58.648632	2025-11-03 12:40:58.648632
487	12	1	8	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
488	1	12	9	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
489	1	3	8	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
490	3	1	9	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
491	3	4	8	1	0.95	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
492	4	3	9	1	0.95	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
493	4	13	8	1	0.93	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
494	13	4	9	1	0.93	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
495	13	14	8	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
496	14	13	9	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
497	17	5	8	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
498	5	17	9	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
499	5	6	8	1	0.94	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
500	6	5	9	1	0.94	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
501	6	18	8	1	0.91	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
502	18	6	9	1	0.91	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
503	18	19	8	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
504	19	18	9	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
505	7	21	8	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
506	21	7	9	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
507	21	22	8	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
508	22	21	9	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
509	8	21	8	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
510	21	8	9	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
511	23	24	8	1	0.91	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
512	24	23	9	1	0.91	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
513	24	25	8	1	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
514	25	24	9	1	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
515	26	27	8	1	0.93	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
516	27	26	9	1	0.93	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
517	27	28	8	1	0.89	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
518	28	27	9	1	0.89	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
519	29	9	8	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
520	9	29	9	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
521	9	30	8	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
522	30	9	9	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
523	30	10	8	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
524	10	30	9	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
525	10	31	8	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
526	31	10	9	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
527	10	32	8	1	0.8	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
528	32	10	9	1	0.8	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
529	33	34	8	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
530	34	33	9	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
531	34	36	8	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
532	36	34	9	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
533	37	38	8	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
534	38	37	9	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
535	38	39	8	1	0.86	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
536	39	38	9	1	0.86	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
537	12	1	11	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
538	12	3	11	2	0.8	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
539	1	3	11	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
540	1	4	11	2	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
541	3	4	11	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
542	3	13	11	2	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
543	4	13	11	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
544	4	14	11	2	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
545	13	14	11	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
546	3	15	11	3	0.75	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
547	4	16	11	3	0.78	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
548	17	5	11	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
549	5	6	11	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
550	6	18	11	1	0.89	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
551	18	19	11	1	0.82	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
552	29	9	11	1	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
553	9	30	11	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
554	30	10	11	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
555	10	31	11	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
556	10	32	11	2	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
557	33	34	11	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
558	34	35	11	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
559	34	36	11	2	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
560	37	38	11	1	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
561	38	39	11	1	0.89	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
562	40	41	11	1	0.83	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
563	43	44	11	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
564	44	45	11	1	0.8	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
565	46	47	11	1	0.82	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
566	1	9	1	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
567	1	10	1	2	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
568	3	9	1	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
569	3	10	1	2	0.95	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
570	3	31	1	3	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
571	4	10	1	1	0.93	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
572	4	31	1	2	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
573	7	34	1	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
574	7	35	1	2	0.82	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
575	8	33	1	1	0.83	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
576	21	34	1	1	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
577	22	35	1	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
578	5	40	1	1	0.8	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
579	6	41	1	1	0.82	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
580	18	43	1	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
581	33	43	1	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
582	34	43	1	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
583	34	44	1	2	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
584	35	44	1	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
585	35	46	1	2	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
586	37	43	1	1	0.86	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
587	38	44	1	1	0.89	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
588	39	46	1	1	0.91	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
589	9	33	1	2	0.82	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
590	10	34	1	2	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
591	29	33	1	1	0.8	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
592	30	34	1	1	0.83	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
593	31	35	1	1	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
594	1	11	1	3	0.7	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
595	3	11	1	3	0.72	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
596	4	48	1	3	0.68	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
597	13	48	1	3	0.7	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
598	14	49	1	3	0.69	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
599	11	3	1	1	0.75	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
600	48	13	1	1	0.72	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
601	7	8	1	2	0.78	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
602	8	7	1	2	0.78	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
603	8	53	1	2	0.75	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
604	21	54	1	2	0.77	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
605	9	57	1	3	0.65	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
606	10	57	1	3	0.68	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
607	31	58	1	3	0.7	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
608	9	1	6	2	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
609	9	4	6	3	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
610	10	4	6	2	0.94	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
611	10	13	6	3	0.91	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
612	29	1	6	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
613	30	3	6	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
614	31	4	6	1	0.93	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
615	31	13	6	2	0.91	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
616	43	33	6	1	0.95	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
617	43	34	6	2	0.93	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
618	44	34	6	1	0.96	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
619	44	35	6	2	0.94	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
620	44	38	6	3	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
621	46	35	6	1	0.97	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
622	46	39	6	2	0.95	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
623	47	39	6	1	0.96	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
624	40	57	6	1	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
625	41	58	6	1	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
626	33	1	2	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
627	33	7	2	2	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
628	34	3	2	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
629	34	8	2	2	0.87	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
630	35	4	2	1	0.92	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
631	35	21	2	2	0.89	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
632	37	7	2	1	0.86	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
633	38	8	2	1	0.88	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
634	39	21	2	1	0.9	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
635	33	43	2	3	0.8	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
636	34	43	2	3	0.82	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
637	34	44	2	4	0.8	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
638	35	44	2	3	0.85	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
639	35	46	2	4	0.82	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
\.


--
-- Data for Name: product_status; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_status (status_id, status_code, status_name, description, is_active, display_order, created_at, updated_at) FROM stdin;
1	ACTIVE	Active	\N	t	1	2025-10-31 14:51:39.288808	2025-10-31 14:51:39.288808
2	DRAFT	Draft	\N	t	2	2025-10-31 14:51:39.288808	2025-10-31 14:51:39.288808
3	PREORDER	Pre-Order	\N	t	3	2025-10-31 14:51:39.288808	2025-10-31 14:51:39.288808
4	DISCONTINUED	Discontinued	\N	t	4	2025-10-31 14:51:39.288808	2025-10-31 14:51:39.288808
5	OUT_OF_STOCK	Out of Stock	\N	t	5	2025-10-31 14:51:39.288808	2025-10-31 14:51:39.288808
\.


--
-- Data for Name: product_suppliers; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_suppliers (product_supplier_id, product_id, supplier_id, is_primary, supplier_product_code, supplier_sku, purchase_order_minimum, purchase_lead_time_days, supplier_cost, supplier_currency, last_purchase_date, last_purchase_price, is_preferred, notes, is_active, created_at, updated_at) FROM stdin;
1	1	1	t	ABC-BRG-6205	ABC6205-BREW	10	3	12.5	USD	2025-10-15	12.5	t	\N	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	1	2	f	GRA-4ABC1	ABC6205-BREW-GRA	5	5	13.75	USD	2025-09-20	13.75	f	\N	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
3	2	2	t	GRA-4RKL8	GRU-CR58	1	7	1850	USD	2025-10-01	1850	t	\N	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
4	2	3	f	PMP-GR-CR58	GRUNDFOS-CR5-8	1	10	1795	USD	2025-08-15	1795	t	\N	t	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
34	12	1	t	ABC-BRG-6203-AUTH	ABC6203-SOL	10	7	4.5	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
35	13	1	t	ABC-BRG-6207-AUTH	ABC6207-STEAM	10	7	8.75	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
36	14	1	t	ABC-BRG-6208-AUTH	ABC6208-BOILER	10	7	10.2	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
37	15	1	t	ABC-BRG-6205C3-AUTH	ABC6205-HOT	10	10	6.8	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
38	16	1	t	ABC-BRG-6206C3-AUTH	ABC6206-DOSE	10	10	9.5	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
39	48	1	t	ABC-BRG-23120-AUTH	ABC23120-ROAST	5	14	145	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
40	49	1	t	ABC-BRG-23122-AUTH	ABC23122-ROAST	5	14	185	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
41	17	2	t	TIM-30204-DIST	30204	10	10	6.2	USD	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
42	18	2	t	TIM-30207-DIST	30207	10	10	14.5	USD	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
43	19	2	t	TIM-32208-DIST	32208	10	12	18.8	USD	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
44	50	2	t	TIM-33109-DIST	33109	15	10	12.5	USD	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
45	51	2	t	TIM-33110-DIST	33110	15	10	15.2	USD	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
46	8	3	t	NSK-7205B-DIST	7205B	20	14	5.8	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
47	21	3	t	NSK-7206B-DIST	7206B	20	14	7.9	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
48	22	3	t	NSK-7208B-DIST	7208B	20	14	12.5	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
49	53	3	t	NSK-6305ZZ-DIST	6305ZZ	20	10	4.2	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
50	54	3	t	NSK-6306DDU-DIST	6306DDU	20	10	6.5	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
51	29	4	t	GRU-CR1-4-FACTORY	CR1-4	1	21	850	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
52	30	4	t	GRU-CR3-8-FACTORY	CR3-8	1	21	1250	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
53	31	4	t	GRU-CR10-6-FACTORY	CR10-6	1	28	2850	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
54	32	4	t	GRU-CRE5-4-FACTORY	CRE5-4	1	35	1850	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
55	57	4	t	GRU-TP32-120-FACTORY	TP32-120/2	1	28	1650	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
56	58	4	t	GRU-TP40-180-FACTORY	TP40-180/2	1	28	2150	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
57	33	5	t	ABB-M2QA90S-DIST	M2QA90S	2	14	285	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
58	34	5	t	ABB-M3BP90S-DIST	M3BP90S	2	14	320	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
59	35	5	t	ABB-M3BP100L-DIST	M3BP100L	2	14	485	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
60	36	5	t	ABB-M3GP90L-DIST	M3GP90L	2	21	580	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
61	59	5	t	ABB-M2BAX100LA-DIST	M2BAX100LA	1	21	650	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
62	60	5	t	ABB-M2BAX112M-DIST	M2BAX112M	1	21	850	EUR	\N	\N	t	\N	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
\.


--
-- Data for Name: product_system_requirements; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_system_requirements (requirement_id, product_id, requirement_type, operating_system, processor, memory_gb, storage_gb, graphics_card, additional_requirements, created_at, updated_at) FROM stdin;
1	2	minimum	Three-phase power supply: 230/400V, 50Hz	Circuit breaker: 16A	\N	\N	\N	Mounting: Concrete foundation or structural steel base. Inlet pressure: 0-6 bar. Ambient temperature: 0-40°C. Installation: Vertical orientation only. Clearance: Minimum 500mm above pump for maintenance access.	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
\.


--
-- Data for Name: product_tag_assignments; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_tag_assignments (assignment_id, product_id, tag_id, created_at) FROM stdin;
1	1	1	2025-10-31 14:52:11.655933
2	1	2	2025-10-31 14:52:11.655933
3	1	5	2025-10-31 14:52:11.655933
4	1	6	2025-10-31 14:52:11.655933
5	1	7	2025-10-31 14:52:11.655933
6	2	1	2025-10-31 14:52:11.655933
7	2	3	2025-10-31 14:52:11.655933
8	2	4	2025-10-31 14:52:11.655933
9	2	5	2025-10-31 14:52:11.655933
10	2	8	2025-10-31 14:52:11.655933
35	14	1	2025-11-03 11:05:46.341181
36	15	1	2025-11-03 11:05:46.341181
37	16	1	2025-11-03 11:05:46.341181
38	19	1	2025-11-03 11:05:46.341181
39	22	1	2025-11-03 11:05:46.341181
40	25	1	2025-11-03 11:05:46.341181
41	32	3	2025-11-03 11:05:46.341181
42	34	3	2025-11-03 11:05:46.341181
43	35	3	2025-11-03 11:05:46.341181
44	36	3	2025-11-03 11:05:46.341181
45	37	3	2025-11-03 11:05:46.341181
46	38	3	2025-11-03 11:05:46.341181
47	39	3	2025-11-03 11:05:46.341181
48	18	4	2025-11-03 11:05:46.341181
49	19	4	2025-11-03 11:05:46.341181
50	31	4	2025-11-03 11:05:46.341181
51	45	4	2025-11-03 11:05:46.341181
52	47	4	2025-11-03 11:05:46.341181
53	60	4	2025-11-03 11:05:46.341181
54	61	4	2025-11-03 11:05:46.341181
55	14	5	2025-11-03 11:05:46.341181
56	32	5	2025-11-03 11:05:46.341181
57	36	5	2025-11-03 11:05:46.341181
58	3	6	2025-11-03 11:05:46.341181
59	10	6	2025-11-03 11:05:46.341181
60	34	6	2025-11-03 11:05:46.341181
\.


--
-- Data for Name: product_tags; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.product_tags (tag_id, tag_name, tag_category, description, is_active, created_at) FROM stdin;
1	High Performance	feature	Products with superior performance characteristics	t	2025-10-31 14:52:11.655933
2	Sealed	feature	Products with integrated sealing	t	2025-10-31 14:52:11.655933
3	Energy Efficient	feature	Products designed for energy efficiency	t	2025-10-31 14:52:11.655933
4	Corrosion Resistant	feature	Products resistant to corrosion	t	2025-10-31 14:52:11.655933
5	Industrial	use-case	Designed for industrial applications	t	2025-10-31 14:52:11.655933
6	OEM	audience	Suitable for original equipment manufacturers	t	2025-10-31 14:52:11.655933
7	MRO	audience	Maintenance, Repair, and Operations	t	2025-10-31 14:52:11.655933
8	Variable Speed	feature	Supports variable speed operation	t	2025-10-31 14:52:11.655933
9	Explosion Proof	feature	Rated for explosive atmospheres	t	2025-11-03 10:01:50.91585
10	Stainless Steel	material	Constructed from stainless steel	t	2025-11-03 10:01:50.91585
11	IP67	certification	IP67 rated for dust and water protection	t	2025-11-03 10:01:50.91585
12	ATEX	certification	ATEX certified for explosive atmospheres	t	2025-11-03 10:01:50.91585
13	Food Grade	certification	FDA approved for food contact	t	2025-11-03 10:01:50.91585
14	IoT Enabled	feature	Connected device with IoT capabilities	t	2025-11-03 10:01:50.91585
15	Compact Design	feature	Space-saving compact design	t	2025-11-03 10:01:50.91585
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.products (product_id, sku, upc, ean, gtin, mpn, asin, product_name, short_description, long_description, brand_id, manufacturer_id, product_line, product_series, model_number, status_id, launch_date, discontinuation_date, primary_category_id, department_id, length_value, width_value, height_value, dimension_uom_id, weight_gross, weight_net, weight_uom_id, volume_value, volume_uom_id, color_name, color_code, size_value, material_composition, packaging_type, packaging_length, packaging_width, packaging_height, packaging_weight, packaging_uom_id, base_uom_id, units_per_package, units_per_case, units_per_pallet, parent_product_id, is_variant, created_at, updated_at) FROM stdin;
1	ABC-BRG-6205	025789456123	7316577001467	07316577001467	6205-2Z	\N	ABC Coffee Brew Pump Bearing Cartridge	Shielded bearing cartridge for commercial espresso brew pumps	ABC Coffee brew pump bearing cartridge uses a shielded 6205-format assembly for commercial espresso pump drives and grinder motors. It is pre-lubricated for continuous duty, optimized for food-service maintenance teams, and packaged as an OEM spare for quick field replacement.	1	1	Deep Groove Ball Bearings	\N	6205-2Z	1	2018-03-15	\N	7	1	52	15	52	4	0.128	0.128	9	\N	\N	Silver/Grey	\N	\N	Chrome steel races, steel cage, metal shields	Individual Box	60	60	20	0.15	4	1	1	10	\N	\N	f	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	GRU-CR5-8-A-FGJ-A-E-HQQE	502789456789	5710315022346	05710315022346	CR5-8 A-FGJ-A-E-HQQE	\N	Grundfos CR5-8 Vertical Multi-Stage Centrifugal Pump 3.0kW	Vertical multi-stage centrifugal pump, 8 stages, 1.5" connections, 3.0kW motor	The Grundfos CR5-8 is a high-efficiency vertical multi-stage centrifugal pump designed for pressure boosting, industrial circulation, and process applications. Features 8 stages for high pressure capability, stainless steel construction for corrosion resistance, and a 3.0kW three-phase motor. The compact vertical design saves floor space while delivering reliable performance. Suitable for water supply, HVAC systems, industrial washdown, reverse osmosis, and light chemical handling. Maximum flow rate 5.5 m³/h, maximum head 72 meters. Built with Grundfos quality for long service life and minimal maintenance.	2	2	CR Series	CR	CR5-8	1	2019-06-20	\N	8	2	430	190	360	5	35	33.5	9	\N	\N	Stainless Steel	\N	\N	Stainless steel pump head and stages, Cast iron motor housing, EPDM O-rings	Wooden Crate	500	250	450	37	5	1	1	1	\N	\N	f	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
3	ABC-BRG-6204	025789456130	7316577002174	07316577002174	6204-2RS	\N	ABC Coffee Group Head Bearing Cartridge	Sealed bearing cartridge for espresso group head drive assemblies	ABC Coffee 6204-format sealed cartridge protects against moisture and coffee dust in brew group actuators and compact pump drives. It is designed for service technicians maintaining espresso machines in high-usage retail environments.	1	1	Deep Groove Ball Bearings	\N	6204-2RS	1	2018-01-10	\N	7	1	47	14	47	4	0.095	0.095	9	\N	\N	Silver/Grey	\N	\N	Chrome steel, rubber seals	Individual Box	55	55	18	0.12	4	1	1	10	\N	\N	f	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
4	ABC-BRG-6206	025789456147	7316577003881	07316577003881	6206-2Z	\N	ABC Coffee Grinder Motor Bearing Cartridge	Shielded bearing cartridge for grinder and dosing motors	ABC Coffee 6206-format bearing cartridge supports grinder and dosing motor assemblies in high-cycle beverage equipment. The shielded design balances contamination control with thermal stability for back-of-house service operations.	1	1	Deep Groove Ball Bearings	\N	6206-2Z	1	2018-03-15	\N	7	1	62	16	62	4	0.198	0.198	9	\N	\N	Silver/Grey	\N	\N	Chrome steel	Individual Box	70	70	22	0.22	4	1	1	10	\N	\N	f	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
5	TIMKEN-30205	123456780001	8573801234567	08573801234567	30205	\N	Timken 30205 Tapered Roller Bearing	Tapered roller bearing, 25mm bore, high radial and thrust capacity	Timken 30205 tapered roller bearing designed for combined radial and thrust loads. Ideal for automotive and industrial gearboxes.	5	5	Tapered Roller Bearings	\N	30205	1	2017-09-01	\N	23	1	52	15	52	4	0.145	0.145	9	\N	\N	Silver	\N	\N	Alloy Steel	Individual Box	60	60	20	0.17	4	1	1	8	\N	\N	f	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
6	TIMKEN-30206	123456780002	8573801234574	08573801234574	30206	\N	Timken 30206 Tapered Roller Bearing	Tapered roller bearing, 30mm bore	Timken 30206 tapered roller bearing with 30mm bore. Premium quality for demanding applications.	5	5	Tapered Roller Bearings	\N	30206	1	2017-09-01	\N	23	1	62	17.25	62	4	0.23	0.23	9	\N	\N	Silver	\N	\N	Alloy Steel	Individual Box	70	70	24	0.26	4	1	1	8	\N	\N	f	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
7	NSK-6205VV	456789120001	4547809123456	04547809123456	6205VV	\N	NSK 6205VV Deep Groove Ball Bearing	Double sealed bearing, 25mm bore	NSK 6205VV with double rubber seals for maximum protection. Pre-lubricated for extended service life.	6	6	Deep Groove Ball Bearings	\N	6205VV	1	2019-02-14	\N	7	1	52	15	52	4	0.13	0.13	9	\N	\N	Silver/Grey	\N	\N	Chrome Steel, Rubber seals	Individual Box	60	60	20	0.15	4	1	1	10	\N	\N	f	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
8	NSK-7205B	456789120008	4547809123463	04547809123463	7205B	\N	NSK 7205B Angular Contact Ball Bearing	Angular contact bearing, 25mm bore, 40° contact angle	NSK 7205B angular contact ball bearing designed for high-speed and precision applications. 40° contact angle for thrust loads.	6	6	Angular Contact Ball Bearings	\N	7205B	1	2019-05-20	\N	22	1	52	15	52	4	0.138	0.138	9	\N	\N	Silver	\N	\N	Chrome Steel	Individual Box	60	60	20	0.16	4	1	1	8	\N	\N	f	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
9	ABC-BRG-22205	025789456154	7316577004598	07316577004598	22205 E	\N	ABC Coffee Roaster Drum Support Bearing	Self-aligning bearing for coffee roaster drum support assemblies	ABC Coffee self-aligning support bearing is used in medium-duty coffee roasters and bulk bean handling assets where shaft deflection must be tolerated without sacrificing uptime.	1	1	Spherical Roller Bearings	\N	22205 E	1	2018-11-01	\N	19	1	52	18	52	4	0.197	0.197	9	\N	\N	Bronze/Grey	\N	\N	Alloy steel	Individual Box	65	65	25	0.23	4	1	1	6	\N	\N	f	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
10	TIMKEN-LM67048/10	123456780010	8573801234581	08573801234581	LM67048/LM67010	\N	Timken LM67048/10 Tapered Roller Bearing Set	Bearing set (cone and cup), imperial size	Timken LM67048/LM67010 tapered roller bearing set. Widely used in automotive wheel hubs and trailers.	5	5	Tapered Roller Bearings	\N	LM67048/10	1	2016-04-15	\N	23	1	45.2	15.5	45.2	4	0.185	0.185	9	\N	\N	Silver	\N	\N	Alloy Steel	Individual Box	55	55	22	0.22	4	1	1	5	\N	\N	f	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
11	GRU-CR3-6-A-FGJ	502789456796	5710315022353	05710315022353	CR3-6	\N	Grundfos CR3-6 Vertical Multi-Stage Pump 1.5kW	Compact 6-stage pump, 1\\" connections	Grundfos CR3-6 vertical multi-stage pump ideal for pressure boosting in residential and light commercial applications.	2	2	CR Series	\N	CR3-6	1	2019-06-20	\N	8	2	380	170	320	5	22	21	9	\N	\N	Stainless Steel	\N	\N	Stainless steel construction	Cardboard Box	420	200	360	24	5	1	1	1	\N	\N	f	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
54	NSK-6306DDU	\N	\N	\N	\N	\N	NSK 6306DDU Deep Groove Ball Bearing	Contact sealed deep groove bearing	NSK 6306DDU with contact seals for maximum protection in contaminated environments.	3	3	Deep Groove Ball Bearings	63 Series	6306DDU	1	2023-12-10	\N	2	1	30	30	11	2	0.125	0.12	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
12	ABC-BRG-6203	\N	\N	\N	\N	\N	ABC Coffee Solenoid Pivot Bearing	Compact shielded bearing for solenoid and valve pivots	ABC Coffee 6203-format shielded bearing is used in compact solenoid pivots and valve actuation points across beverage equipment.	1	1	Deep Groove Ball Bearings	62 Series	6203-2Z	1	2020-01-15	\N	2	1	17	17	7	2	0.045	0.042	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
13	ABC-BRG-6207	\N	\N	\N	\N	\N	ABC Coffee Steam Pump Shaft Bearing	Large-capacity shielded bearing for steam pump shafts	ABC Coffee 6207-format shielded bearing supports steam pump shafts and other higher-load rotating assemblies in professional beverage equipment.	1	1	Deep Groove Ball Bearings	62 Series	6207-2Z	1	2023-06-01	\N	2	1	35	35	11	2	0.145	0.14	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
14	ABC-BRG-6208	\N	\N	\N	\N	\N	ABC Coffee Boiler Circulation Bearing	Premium sealed bearing for boiler circulation assemblies	ABC Coffee 6208-format sealed bearing is used where hot-water circulation equipment needs additional protection from steam and cleaning cycles.	1	1	Deep Groove Ball Bearings	62 Series	6208-2RS	1	2024-03-15	\N	2	1	40	40	12	2	0.18	0.175	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
15	ABC-BRG-6205-C3	\N	\N	\N	\N	\N	ABC Coffee High-Temp Brew Group Bearing	C3 clearance bearing for high-temperature brew group zones	ABC Coffee high-temp brew group bearing uses increased internal clearance to remain stable across repeated heating and cooling cycles in commercial espresso equipment.	1	1	Deep Groove Ball Bearings	62 Series	6205-2Z/C3	1	2022-09-01	\N	2	1	25	25	9	2	0.075	0.072	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
16	ABC-BRG-6206-C3	\N	\N	\N	\N	\N	ABC Coffee Sealed Dosing Motor Bearing	Sealed C3 bearing for dosing and grinder motor assemblies	ABC Coffee sealed dosing motor bearing combines C3 clearance and additional sealing for high-cycle grinder and dosing motor applications.	1	1	Deep Groove Ball Bearings	62 Series	6206-2RS/C3	1	2023-02-20	\N	2	1	30	30	10	2	0.095	0.092	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4	t	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
17	TIM-30204	\N	\N	\N	\N	\N	Timken 30204 Tapered Roller Bearing	Compact tapered roller bearing	Timken 30204 single row tapered roller bearing for light to medium loads.	2	2	Tapered Roller Bearings	302 Series	30204	4	2018-05-10	2023-12-31	3	1	20	20	14	2	0.068	0.065	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
18	TIM-30207	\N	\N	\N	\N	\N	Timken 30207 Tapered Roller Bearing	Heavy-duty tapered roller bearing	Timken 30207 designed for heavy radial and thrust loads in industrial applications.	2	2	Tapered Roller Bearings	302 Series	30207	1	2022-03-15	\N	3	1	35	35	18	2	0.195	0.19	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
19	TIM-32208	\N	\N	\N	\N	\N	Timken 32208 Tapered Roller Bearing	Next-gen tapered bearing with enhanced design	Timken 32208 features improved cage design and optimized geometry for longer life and higher performance.	2	2	Tapered Roller Bearings	322 Series	32208	1	2024-01-10	\N	3	1	40	40	19	2	0.225	0.22	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
21	NSK-7206B	\N	\N	\N	\N	\N	NSK 7206B Angular Contact Ball Bearing	Medium capacity angular contact bearing	NSK 7206B for higher loads with precision machined raceways.	3	3	Angular Contact Ball Bearings	72 Series	7206B	1	2022-11-05	\N	5	1	30	30	10	2	0.11	0.105	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
22	NSK-7208B	\N	\N	\N	\N	\N	NSK 7208B Angular Contact Ball Bearing	High-performance angular contact bearing	NSK 7208B latest generation with optimized internal geometry for extended service life.	3	3	Angular Contact Ball Bearings	72 Series	7208B	1	2024-05-12	\N	5	1	40	40	12	2	0.165	0.16	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
23	FAG-NU204	\N	\N	\N	\N	\N	FAG NU204 Cylindrical Roller Bearing	Single row cylindrical roller bearing	FAG NU204 cylindrical roller bearing with high radial load capacity and low friction.	4	4	Cylindrical Roller Bearings	NU Series	NU204	1	2020-07-15	\N	4	1	20	20	12	2	0.055	0.052	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
24	FAG-NU206	\N	\N	\N	\N	\N	FAG NU206 Cylindrical Roller Bearing	Medium capacity cylindrical bearing	FAG NU206 for applications requiring high radial load capacity with minimal axial guidance.	4	4	Cylindrical Roller Bearings	NU Series	NU206	1	2022-04-10	\N	4	1	30	30	13	2	0.098	0.095	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
25	FAG-NU208-E	\N	\N	\N	\N	\N	FAG NU208-E Cylindrical Roller Bearing	Enhanced cylindrical roller bearing	FAG NU208-E with optimized roller profile and cage design for maximum performance.	4	4	Cylindrical Roller Bearings	NU Series	NU208-E	1	2024-02-28	\N	4	1	40	40	14	2	0.145	0.14	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
26	NTN-1205	\N	\N	\N	\N	\N	NTN 1205 Self-Aligning Ball Bearing	Double row self-aligning bearing	NTN 1205 self-aligning ball bearing compensates for shaft deflection and misalignment.	5	5	Self-Aligning Ball Bearings	12 Series	1205	1	2021-03-18	\N	6	1	25	25	11	2	0.088	0.085	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
27	NTN-1206	\N	\N	\N	\N	\N	NTN 1206 Self-Aligning Ball Bearing	Medium self-aligning bearing	NTN 1206 provides excellent performance in applications with shaft misalignment.	5	5	Self-Aligning Ball Bearings	12 Series	1206	1	2022-08-22	\N	6	1	30	30	13	2	0.115	0.11	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
28	NTN-1208K	\N	\N	\N	\N	\N	NTN 1208K Self-Aligning Ball Bearing	Self-aligning bearing with tapered bore	NTN 1208K features tapered bore (1:12) for easy mounting on adapter sleeves.	5	5	Self-Aligning Ball Bearings	12 Series	1208K	1	2023-11-30	\N	6	1	40	40	14	2	0.158	0.152	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
29	GRU-CR1-4-A-FGJ-A-E-HQQE	\N	\N	\N	\N	\N	Grundfos CR1-4 Vertical Multi-Stage Centrifugal Pump 1.1kW	Compact 4-stage vertical pump	Grundfos CR1-4 energy-efficient vertical multi-stage centrifugal pump, 1.1kW motor.	6	6	CR Series Vertical Pumps	CR Series	CR1-4	1	2020-09-01	\N	7	2	185	165	385	2	18.5	17.8	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
30	GRU-CR3-8-A-FGJ-A-E-HQQE	\N	\N	\N	\N	\N	Grundfos CR3-8 Vertical Multi-Stage Centrifugal Pump 2.2kW	8-stage vertical pump with higher capacity	Grundfos CR3-8 vertical multi-stage pump with 8 stages for increased pressure, 2.2kW motor.	6	6	CR Series Vertical Pumps	CR Series	CR3-8	1	2022-05-15	\N	7	2	195	175	485	2	28.5	27.2	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
31	GRU-CR10-6-A-FGJ-A-E-HQQE	\N	\N	\N	\N	\N	Grundfos CR10-6 Vertical Multi-Stage Centrifugal Pump 5.5kW	High-capacity 6-stage vertical pump	Grundfos CR10-6 for demanding applications requiring high flow rates, 5.5kW motor.	6	6	CR Series Vertical Pumps	CR Series	CR10-6	1	2023-07-20	\N	7	2	255	235	585	2	52	50.5	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
32	GRU-CRE5-4-A-FGJ-A-E-HQQE	\N	\N	\N	\N	\N	Grundfos CRE5-4 Vertical Multi-Stage Pump with IE5 Motor 2.2kW	Next-gen CR with IE5 ultra-efficient motor	Grundfos CRE5-4 features IE5 synchronous reluctance motor for maximum energy efficiency.	6	6	CRE Series Vertical Pumps	CRE Series	CRE5-4	1	2024-09-10	\N	7	2	205	185	445	2	32	30.8	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
33	ABB-M2QA90S-0.75	\N	\N	\N	\N	\N	ABB M2QA 90S 0.75kW IE2 Electric Motor	IE2 efficiency 3-phase motor	ABB M2QA 90S cast iron frame motor, 0.75kW, 1500 RPM, IE2 efficiency class.	7	7	Process Performance Motors	M2QA Series	M2QA90S	1	2019-04-12	\N	8	3	285	180	180	2	14.5	14	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
34	ABB-M3BP90S-1.1	\N	\N	\N	\N	\N	ABB M3BP 90S 1.1kW IE3 Electric Motor	IE3 premium efficiency motor	ABB M3BP 90S aluminum frame motor, 1.1kW, 1500 RPM, IE3 premium efficiency.	7	7	Process Performance Motors	M3BP Series	M3BP90S	1	2021-06-20	\N	8	3	290	180	180	2	13.8	13.2	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
35	ABB-M3BP100L-2.2	\N	\N	\N	\N	\N	ABB M3BP 100L 2.2kW IE3 Electric Motor	IE3 motor for higher power applications	ABB M3BP 100L aluminum frame motor, 2.2kW, 1500 RPM, IE3 efficiency for industrial use.	7	7	Process Performance Motors	M3BP Series	M3BP100L	1	2022-10-08	\N	8	3	335	200	200	2	21.5	20.8	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
36	ABB-M3GP90L-1.5	\N	\N	\N	\N	\N	ABB M3GP 90L 1.5kW IE4 Electric Motor	IE4 super premium efficiency motor	ABB M3GP 90L synchronous reluctance motor, 1.5kW, 1500 RPM, IE4 super premium efficiency.	7	7	Process Performance Motors	M3GP Series	M3GP90L	1	2024-03-25	\N	8	3	315	190	190	2	19.2	18.5	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
37	SIE-1LE1001-0.75	\N	\N	\N	\N	\N	Siemens 1LE1001 0.75kW IE3 Electric Motor	Compact IE3 motor	Siemens 1LE1001 series aluminum frame motor, 0.75kW, 1500 RPM, IE3 efficiency.	8	8	SIMOTICS GP Motors	1LE1 Series	1LE1001	1	2020-11-15	\N	8	3	280	175	175	2	13.2	12.8	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
38	SIE-1LE1002-1.5	\N	\N	\N	\N	\N	Siemens 1LE1002 1.5kW IE3 Electric Motor	Mid-range IE3 motor	Siemens 1LE1002 aluminum frame motor, 1.5kW, 1500 RPM, suitable for general applications.	8	8	SIMOTICS GP Motors	1LE1 Series	1LE1002	1	2022-01-20	\N	8	3	310	185	185	2	17.5	16.9	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
39	SIE-1LE1501-2.2	\N	\N	\N	\N	\N	Siemens 1LE1501 2.2kW IE4 Electric Motor	IE4 super premium motor	Siemens 1LE1501 with IE4 efficiency, 2.2kW, 1500 RPM, for energy-critical applications.	8	8	SIMOTICS GP Motors	1LE15 Series	1LE1501	1	2023-08-30	\N	8	3	340	195	195	2	23	22.2	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
40	SEW-R37DRE80M4	\N	\N	\N	\N	\N	SEW-EURODRIVE R37 DRE80M4 0.75kW Gearmotor	Helical gearmotor 0.75kW	SEW R37 helical gearmotor with 0.75kW motor, ratio 37:1, torque-arm mounting.	9	9	R Series Helical Gearmotors	R Series	R37DRE80M4	1	2021-02-10	\N	9	3	425	185	235	2	28.5	27.5	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
41	SEW-R47DRE90L4	\N	\N	\N	\N	\N	SEW-EURODRIVE R47 DRE90L4 1.5kW Gearmotor	Helical gearmotor 1.5kW	SEW R47 helical gearmotor with 1.5kW motor, ratio 47:1, foot mounting.	9	9	R Series Helical Gearmotors	R Series	R47DRE90L4	1	2022-07-18	\N	9	3	455	195	250	2	38	36.8	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
42	SEW-F37DRE80M4	\N	\N	\N	\N	\N	SEW-EURODRIVE F37 DRE80M4 0.75kW Parallel Shaft Gearmotor	Parallel shaft gearmotor	SEW F37 parallel shaft gearmotor, 0.75kW motor, ratio 37:1, compact design.	9	9	F Series Parallel Shaft Gearmotors	F Series	F37DRE80M4	1	2023-04-05	\N	9	3	395	165	215	2	24.5	23.8	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
43	NORD-SK02040.1	\N	\N	\N	\N	\N	NORD SK 02040.1 Helical Gearbox i=40	Compact helical gearbox	NORD SK 02040.1 helical gearbox, size 2, ratio 40:1, output torque 400 Nm.	10	10	SK Helical Gearboxes	SK Series	SK02040.1	1	2020-05-22	\N	10	3	285	165	185	2	18.5	17.9	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
44	NORD-SK03063.1	\N	\N	\N	\N	\N	NORD SK 03063.1 Helical Gearbox i=63	Medium helical gearbox	NORD SK 03063.1 helical gearbox, size 3, ratio 63:1, output torque 850 Nm.	10	10	SK Helical Gearboxes	SK Series	SK03063.1	1	2022-03-14	\N	10	3	335	195	215	2	32	31	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
45	NORD-SK1382.1	\N	\N	\N	\N	\N	NORD SK 1382.1 Helical Gearbox i=82	Heavy-duty helical gearbox	NORD SK 1382.1 helical gearbox, size 13, ratio 82:1, output torque 18,000 Nm.	10	10	SK Helical Gearboxes	SK Series	SK1382.1	1	2023-11-08	\N	10	3	685	425	515	2	285	278	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
46	FLENDER-B3SH06	\N	\N	\N	\N	\N	Flender B3SH06 Bevel-Helical Gearbox	Right-angle bevel-helical gearbox	Flender B3SH06 bevel-helical gearbox for right-angle drive applications, high efficiency.	11	11	B3SH Bevel-Helical Gearboxes	B3SH Series	B3SH06	1	2021-09-12	\N	11	3	385	245	285	2	58	56.5	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
47	FLENDER-B3SH08	\N	\N	\N	\N	\N	Flender B3SH08 Bevel-Helical Gearbox	Medium capacity bevel-helical gearbox	Flender B3SH08 for medium to heavy-duty applications, optimized tooth geometry.	11	11	B3SH Bevel-Helical Gearboxes	B3SH Series	B3SH08	1	2023-02-25	\N	11	3	465	295	345	2	95	92.5	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
48	ABC-BRG-23120	\N	\N	\N	\N	\N	ABC Coffee Roaster Drum Roller Bearing	Heavy-duty roller bearing for coffee roaster drums	ABC Coffee roaster drum roller bearing is designed for bean roasting systems where high heat and continuous rotation require stable load handling.	1	1	Spherical Roller Bearings	231 Series	23120CC/W33	1	2022-06-18	\N	12	1	100	100	38	2	2.85	2.8	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
49	ABC-BRG-23122	\N	\N	\N	\N	\N	ABC Coffee Roaster Main Support Bearing	Large spherical roller bearing for main support frames	ABC Coffee main support bearing is used in larger roasting and bulk grinding frames where heavy radial loads and shaft misalignment are expected.	1	1	Spherical Roller Bearings	231 Series	23122CC/W33	1	2023-10-05	\N	12	1	110	110	41	2	3.75	3.68	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
50	TIM-33109	\N	\N	\N	\N	\N	Timken 33109 Tapered Roller Bearing	Metric tapered roller bearing	Timken 33109 metric series tapered roller bearing for wheel bearings and industrial applications.	2	2	Tapered Roller Bearings	331 Series	33109	1	2021-12-08	\N	3	1	45	45	20	2	0.385	0.375	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
51	TIM-33110	\N	\N	\N	\N	\N	Timken 33110 Tapered Roller Bearing	Medium metric tapered bearing	Timken 33110 metric tapered roller bearing with enhanced load rating.	2	2	Tapered Roller Bearings	331 Series	33110	1	2022-05-20	\N	3	1	50	50	22	2	0.485	0.47	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
52	FAG-NJ206-E-TVP2	\N	\N	\N	\N	\N	FAG NJ206-E-TVP2 Cylindrical Roller Bearing	Enhanced cylindrical with polyamide cage	FAG NJ206-E-TVP2 with optimized design and glass fiber reinforced polyamide cage.	4	4	Cylindrical Roller Bearings	NJ Series	NJ206-E-TVP2	1	2023-07-12	\N	4	1	30	30	13	2	0.102	0.098	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
53	NSK-6305ZZ	\N	\N	\N	\N	\N	NSK 6305ZZ Deep Groove Ball Bearing	Shielded deep groove bearing	NSK 6305ZZ with metal shields, suitable for high-speed applications.	3	3	Deep Groove Ball Bearings	63 Series	6305ZZ	1	2022-08-30	\N	2	1	25	25	10	2	0.095	0.092	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
55	NTN-22208B	\N	\N	\N	\N	\N	NTN 22208B Spherical Roller Bearing	E-design spherical roller bearing	NTN 22208B with optimized internal design for extended service life.	5	5	Spherical Roller Bearings	222 Series	22208B	1	2022-11-22	\N	12	1	40	40	18	2	0.358	0.35	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
56	NTN-22210BK	\N	\N	\N	\N	\N	NTN 22210BK Spherical Roller Bearing	Spherical roller bearing with tapered bore	NTN 22210BK with 1:12 tapered bore for adapter sleeve mounting.	5	5	Spherical Roller Bearings	222 Series	22210BK	1	2024-01-18	\N	12	1	50	50	22	2	0.598	0.585	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
57	GRU-TP32-120-2	\N	\N	\N	\N	\N	Grundfos TP 32-120/2 Inline Circulator Pump	Twin-head inline circulator	Grundfos TP 32-120/2 inline circulator pump with 2 pump ends for HVAC applications.	6	6	TP Series Inline Pumps	TP Series	TP32-120/2	1	2021-06-25	\N	13	2	340	220	280	2	45	43.5	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
58	GRU-TP40-180-2	\N	\N	\N	\N	\N	Grundfos TP 40-180/2 Inline Circulator Pump	High-capacity twin-head circulator	Grundfos TP 40-180/2 for large HVAC systems requiring high flow rates.	6	6	TP Series Inline Pumps	TP Series	TP40-180/2	1	2023-03-08	\N	13	2	385	250	320	2	68	66	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
59	ABB-M2BAX100LA-3.0	\N	\N	\N	\N	\N	ABB M2BAX 100LA 3.0kW Brake Motor	IE2 motor with integrated brake	ABB M2BAX 100LA with DC brake, 3.0kW, 1500 RPM, for crane and hoist applications.	7	7	Process Performance Motors	M2BAX Series	M2BAX100LA	1	2020-10-12	\N	14	3	395	210	210	2	35.5	34.2	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
60	ABB-M2BAX112M-4.0	\N	\N	\N	\N	\N	ABB M2BAX 112M 4.0kW Brake Motor	IE2 brake motor for heavy duty	ABB M2BAX 112M with DC brake, 4.0kW, 1500 RPM, heavy-duty design.	7	7	Process Performance Motors	M2BAX Series	M2BAX112M	1	2022-04-28	\N	14	3	435	225	225	2	48	46.5	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
61	SIE-1LG4186-11	\N	\N	\N	\N	\N	Siemens 1LG4 186 11kW Slip-Ring Motor	Three-phase slip-ring motor	Siemens 1LG4 186 slip-ring motor, 11kW, 1000 RPM, for high starting torque applications.	8	8	SIMOTICS HV Motors	1LG4 Series	1LG4186	1	2021-11-30	\N	15	3	525	315	315	2	185	180	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	f	2025-11-03 11:05:46.341181	2025-11-03 11:05:46.341181
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.suppliers (supplier_id, supplier_code, supplier_name, supplier_type, contact_name, contact_email, contact_phone, website_url, address_line1, address_line2, city, state_province, postal_code, country_code, payment_terms, tax_id, is_preferred, is_active, rating, notes, created_at, updated_at) FROM stdin;
1	MOTION-IND	Motion Industries Inc.	distributor	John Smith	sales@motion.com	+1-205-956-1122	https://www.motion.com	1605 Alford Avenue	\N	Birmingham	Alabama	35226	USA	Net 30	\N	t	t	4.5	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
2	GRAINGER	W.W. Grainger Inc.	distributor	Sarah Johnson	contact@grainger.com	+1-847-535-1000	https://www.grainger.com	100 Grainger Parkway	\N	Lake Forest	Illinois	60045	USA	Net 45	\N	t	t	4.7	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
3	PUMP-SPEC	Pump Specialties LLC	wholesaler	Mike Anderson	info@pumpspec.com	+1-713-555-0100	https://www.pumpspec.com	4500 Industrial Blvd	\N	Houston	Texas	77032	USA	Net 30	\N	f	t	4.2	\N	2025-10-31 14:52:11.655933	2025-10-31 14:52:11.655933
4	APPLIED-IND	Applied Industrial Technologies	distributor	Lisa Chen	orders@applied.com	+1-216-426-4000	https://www.applied.com	1 Applied Plaza	\N	Cleveland	Ohio	44115	USA	Net 30	\N	t	t	4.6	\N	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
5	MSC-IND	MSC Industrial Supply	distributor	Robert Taylor	sales@mscdirect.com	+1-800-645-7270	https://www.mscdirect.com	75 Maxess Road	\N	Melville	New York	11747	USA	Net 60	\N	t	t	4.4	\N	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
6	AUTOMATION-DIR	Automation Direct	distributor	Jennifer Martinez	support@automationdirect.com	+1-770-889-2858	https://www.automationdirect.com	3505 Hutchinson Road	\N	Cumming	Georgia	30040	USA	Net 30	\N	f	t	4.5	\N	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
7	KAMAN-DIST	Kaman Distribution Group	distributor	David Brown	sales@kamandist.com	+1-800-526-2626	https://www.kamandist.com	1332 Kemper Meadow Drive	\N	Cincinnati	Ohio	45240	USA	Net 45	\N	t	t	4.3	\N	2025-11-03 10:01:50.91585	2025-11-03 10:01:50.91585
\.


--
-- Data for Name: unit_of_measure; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.unit_of_measure (uom_id, uom_code, uom_name, uom_type, description, is_active, created_at) FROM stdin;
1	EA	Each	quantity	\N	t	2025-10-31 14:51:39.307667
2	CS	Case	quantity	\N	t	2025-10-31 14:51:39.307667
3	PLT	Pallet	quantity	\N	t	2025-10-31 14:51:39.307667
4	IN	Inches	length	\N	t	2025-10-31 14:51:39.307667
5	CM	Centimeters	length	\N	t	2025-10-31 14:51:39.307667
6	M	Meters	length	\N	t	2025-10-31 14:51:39.307667
7	FT	Feet	length	\N	t	2025-10-31 14:51:39.307667
8	LB	Pounds	weight	\N	t	2025-10-31 14:51:39.307667
9	KG	Kilograms	weight	\N	t	2025-10-31 14:51:39.307667
10	G	Grams	weight	\N	t	2025-10-31 14:51:39.307667
11	OZ	Ounces	weight	\N	t	2025-10-31 14:51:39.307667
12	GAL	Gallons	volume	\N	t	2025-10-31 14:51:39.307667
13	L	Liters	volume	\N	t	2025-10-31 14:51:39.307667
14	ML	Milliliters	volume	\N	t	2025-10-31 14:51:39.307667
15	CUFT	Cubic Feet	volume	\N	t	2025-10-31 14:51:39.307667
16	CUM	Cubic Meters	volume	\N	t	2025-10-31 14:51:39.307667
\.


--
-- Name: attribute_options_option_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.attribute_options_option_id_seq', 1, false);


--
-- Name: attribute_sets_attribute_set_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.attribute_sets_attribute_set_id_seq', 1, false);


--
-- Name: attributes_attribute_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.attributes_attribute_id_seq', 1, false);


--
-- Name: brands_brand_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.brands_brand_id_seq', 1, false);


--
-- Name: departments_department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.departments_department_id_seq', 1, false);


--
-- Name: manufacturers_manufacturer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.manufacturers_manufacturer_id_seq', 1, false);


--
-- Name: product_attribute_values_value_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_attribute_values_value_id_seq', 506, true);


--
-- Name: product_categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_categories_category_id_seq', 1, false);


--
-- Name: product_category_assignments_assignment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_category_assignments_assignment_id_seq', 20, true);


--
-- Name: product_compatibility_compatibility_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_compatibility_compatibility_id_seq', 51, true);


--
-- Name: product_group_assignments_assignment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_group_assignments_assignment_id_seq', 41, true);


--
-- Name: product_groups_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_groups_group_id_seq', 1, false);


--
-- Name: product_reference_codes_reference_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_reference_codes_reference_id_seq', 6, true);


--
-- Name: product_relationship_types_relationship_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_relationship_types_relationship_type_id_seq', 11, true);


--
-- Name: product_relationships_relationship_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_relationships_relationship_id_seq', 684, true);


--
-- Name: product_status_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_status_status_id_seq', 5, true);


--
-- Name: product_suppliers_product_supplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_suppliers_product_supplier_id_seq', 62, true);


--
-- Name: product_system_requirements_requirement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_system_requirements_requirement_id_seq', 1, true);


--
-- Name: product_tag_assignments_assignment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_tag_assignments_assignment_id_seq', 60, true);


--
-- Name: product_tags_tag_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.product_tags_tag_id_seq', 1, false);


--
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.products_product_id_seq', 61, true);


--
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.suppliers_supplier_id_seq', 1, false);


--
-- Name: unit_of_measure_uom_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.unit_of_measure_uom_id_seq', 16, true);


--
-- Name: attribute_options attribute_options_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attribute_options
    ADD CONSTRAINT attribute_options_pkey PRIMARY KEY (option_id);


--
-- Name: attribute_sets attribute_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attribute_sets
    ADD CONSTRAINT attribute_sets_pkey PRIMARY KEY (attribute_set_id);


--
-- Name: attribute_sets attribute_sets_set_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attribute_sets
    ADD CONSTRAINT attribute_sets_set_code_key UNIQUE (set_code);


--
-- Name: attributes attributes_attribute_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attributes
    ADD CONSTRAINT attributes_attribute_code_key UNIQUE (attribute_code);


--
-- Name: attributes attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attributes
    ADD CONSTRAINT attributes_pkey PRIMARY KEY (attribute_id);


--
-- Name: brands brands_brand_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_brand_code_key UNIQUE (brand_code);


--
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (brand_id);


--
-- Name: departments departments_department_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_department_code_key UNIQUE (department_code);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- Name: manufacturers manufacturers_manufacturer_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.manufacturers
    ADD CONSTRAINT manufacturers_manufacturer_code_key UNIQUE (manufacturer_code);


--
-- Name: manufacturers manufacturers_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.manufacturers
    ADD CONSTRAINT manufacturers_pkey PRIMARY KEY (manufacturer_id);


--
-- Name: product_attribute_values product_attribute_values_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_attribute_values
    ADD CONSTRAINT product_attribute_values_pkey PRIMARY KEY (value_id);


--
-- Name: product_categories product_categories_category_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_category_code_key UNIQUE (category_code);


--
-- Name: product_categories product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (category_id);


--
-- Name: product_category_assignments product_category_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_category_assignments
    ADD CONSTRAINT product_category_assignments_pkey PRIMARY KEY (assignment_id);


--
-- Name: product_compatibility product_compatibility_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_compatibility
    ADD CONSTRAINT product_compatibility_pkey PRIMARY KEY (compatibility_id);


--
-- Name: product_group_assignments product_group_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_group_assignments
    ADD CONSTRAINT product_group_assignments_pkey PRIMARY KEY (assignment_id);


--
-- Name: product_groups product_groups_group_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_groups
    ADD CONSTRAINT product_groups_group_code_key UNIQUE (group_code);


--
-- Name: product_groups product_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_groups
    ADD CONSTRAINT product_groups_pkey PRIMARY KEY (group_id);


--
-- Name: product_reference_codes product_reference_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_reference_codes
    ADD CONSTRAINT product_reference_codes_pkey PRIMARY KEY (reference_id);


--
-- Name: product_relationship_types product_relationship_types_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_relationship_types
    ADD CONSTRAINT product_relationship_types_pkey PRIMARY KEY (relationship_type_id);


--
-- Name: product_relationship_types product_relationship_types_type_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_relationship_types
    ADD CONSTRAINT product_relationship_types_type_code_key UNIQUE (type_code);


--
-- Name: product_relationships product_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_relationships
    ADD CONSTRAINT product_relationships_pkey PRIMARY KEY (relationship_id);


--
-- Name: product_status product_status_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_status
    ADD CONSTRAINT product_status_pkey PRIMARY KEY (status_id);


--
-- Name: product_status product_status_status_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_status
    ADD CONSTRAINT product_status_status_code_key UNIQUE (status_code);


--
-- Name: product_suppliers product_suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_pkey PRIMARY KEY (product_supplier_id);


--
-- Name: product_system_requirements product_system_requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_system_requirements
    ADD CONSTRAINT product_system_requirements_pkey PRIMARY KEY (requirement_id);


--
-- Name: product_tag_assignments product_tag_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_tag_assignments
    ADD CONSTRAINT product_tag_assignments_pkey PRIMARY KEY (assignment_id);


--
-- Name: product_tags product_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_tags
    ADD CONSTRAINT product_tags_pkey PRIMARY KEY (tag_id);


--
-- Name: product_tags product_tags_tag_name_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_tags
    ADD CONSTRAINT product_tags_tag_name_key UNIQUE (tag_name);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- Name: products products_sku_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_sku_key UNIQUE (sku);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (supplier_id);


--
-- Name: suppliers suppliers_supplier_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_supplier_code_key UNIQUE (supplier_code);


--
-- Name: attribute_options unique_attribute_option; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attribute_options
    ADD CONSTRAINT unique_attribute_option UNIQUE (attribute_id, option_value);


--
-- Name: product_compatibility unique_compatibility; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_compatibility
    ADD CONSTRAINT unique_compatibility UNIQUE (product_id, compatible_with_product_id);


--
-- Name: product_attribute_values unique_product_attribute; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_attribute_values
    ADD CONSTRAINT unique_product_attribute UNIQUE (product_id, attribute_id);


--
-- Name: product_category_assignments unique_product_category; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_category_assignments
    ADD CONSTRAINT unique_product_category UNIQUE (product_id, category_id);


--
-- Name: product_group_assignments unique_product_group; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_group_assignments
    ADD CONSTRAINT unique_product_group UNIQUE (product_id, group_id);


--
-- Name: product_reference_codes unique_product_reference; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_reference_codes
    ADD CONSTRAINT unique_product_reference UNIQUE (product_id, code_type, reference_code);


--
-- Name: product_relationships unique_product_relationship; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_relationships
    ADD CONSTRAINT unique_product_relationship UNIQUE (source_product_id, related_product_id, relationship_type_id);


--
-- Name: product_suppliers unique_product_supplier; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT unique_product_supplier UNIQUE (product_id, supplier_id);


--
-- Name: product_tag_assignments unique_product_tag; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_tag_assignments
    ADD CONSTRAINT unique_product_tag UNIQUE (product_id, tag_id);


--
-- Name: unit_of_measure unit_of_measure_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.unit_of_measure
    ADD CONSTRAINT unit_of_measure_pkey PRIMARY KEY (uom_id);


--
-- Name: unit_of_measure unit_of_measure_uom_code_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.unit_of_measure
    ADD CONSTRAINT unit_of_measure_uom_code_key UNIQUE (uom_code);


--
-- Name: idx_product_compatibility_compatible_with; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_product_compatibility_compatible_with ON public.product_compatibility USING btree (compatible_with_product_id);


--
-- Name: idx_product_compatibility_product_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_product_compatibility_product_id ON public.product_compatibility USING btree (product_id);


--
-- Name: idx_product_system_requirements_product_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_product_system_requirements_product_id ON public.product_system_requirements USING btree (product_id);


--
-- Name: attribute_options attribute_options_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.attribute_options
    ADD CONSTRAINT attribute_options_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.attributes(attribute_id) ON DELETE CASCADE;


--
-- Name: departments departments_parent_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_parent_department_id_fkey FOREIGN KEY (parent_department_id) REFERENCES public.departments(department_id);


--
-- Name: product_attribute_values product_attribute_values_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_attribute_values
    ADD CONSTRAINT product_attribute_values_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.attributes(attribute_id);


--
-- Name: product_attribute_values product_attribute_values_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_attribute_values
    ADD CONSTRAINT product_attribute_values_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_categories product_categories_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: product_categories product_categories_parent_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_parent_category_id_fkey FOREIGN KEY (parent_category_id) REFERENCES public.product_categories(category_id);


--
-- Name: product_category_assignments product_category_assignments_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_category_assignments
    ADD CONSTRAINT product_category_assignments_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.product_categories(category_id);


--
-- Name: product_category_assignments product_category_assignments_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_category_assignments
    ADD CONSTRAINT product_category_assignments_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_compatibility product_compatibility_compatible_with_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_compatibility
    ADD CONSTRAINT product_compatibility_compatible_with_product_id_fkey FOREIGN KEY (compatible_with_product_id) REFERENCES public.products(product_id);


--
-- Name: product_compatibility product_compatibility_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_compatibility
    ADD CONSTRAINT product_compatibility_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_group_assignments product_group_assignments_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_group_assignments
    ADD CONSTRAINT product_group_assignments_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.product_groups(group_id);


--
-- Name: product_group_assignments product_group_assignments_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_group_assignments
    ADD CONSTRAINT product_group_assignments_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_reference_codes product_reference_codes_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_reference_codes
    ADD CONSTRAINT product_reference_codes_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_relationships product_relationships_related_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_relationships
    ADD CONSTRAINT product_relationships_related_product_id_fkey FOREIGN KEY (related_product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_relationships product_relationships_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_relationships
    ADD CONSTRAINT product_relationships_relationship_type_id_fkey FOREIGN KEY (relationship_type_id) REFERENCES public.product_relationship_types(relationship_type_id);


--
-- Name: product_relationships product_relationships_source_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_relationships
    ADD CONSTRAINT product_relationships_source_product_id_fkey FOREIGN KEY (source_product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_suppliers product_suppliers_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_suppliers product_suppliers_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(supplier_id);


--
-- Name: product_system_requirements product_system_requirements_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_system_requirements
    ADD CONSTRAINT product_system_requirements_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_tag_assignments product_tag_assignments_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_tag_assignments
    ADD CONSTRAINT product_tag_assignments_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_tag_assignments product_tag_assignments_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.product_tag_assignments
    ADD CONSTRAINT product_tag_assignments_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.product_tags(tag_id);


--
-- Name: products products_base_uom_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_base_uom_id_fkey FOREIGN KEY (base_uom_id) REFERENCES public.unit_of_measure(uom_id);


--
-- Name: products products_brand_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(brand_id);


--
-- Name: products products_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: products products_dimension_uom_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_dimension_uom_id_fkey FOREIGN KEY (dimension_uom_id) REFERENCES public.unit_of_measure(uom_id);


--
-- Name: products products_manufacturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES public.manufacturers(manufacturer_id);


--
-- Name: products products_packaging_uom_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_packaging_uom_id_fkey FOREIGN KEY (packaging_uom_id) REFERENCES public.unit_of_measure(uom_id);


--
-- Name: products products_parent_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_parent_product_id_fkey FOREIGN KEY (parent_product_id) REFERENCES public.products(product_id);


--
-- Name: products products_primary_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_primary_category_id_fkey FOREIGN KEY (primary_category_id) REFERENCES public.product_categories(category_id);


--
-- Name: products products_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.product_status(status_id);


--
-- Name: products products_volume_uom_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_volume_uom_id_fkey FOREIGN KEY (volume_uom_id) REFERENCES public.unit_of_measure(uom_id);


--
-- Name: products products_weight_uom_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_weight_uom_id_fkey FOREIGN KEY (weight_uom_id) REFERENCES public.unit_of_measure(uom_id);


--
-- PostgreSQL database dump complete
--

\unrestrict AlCUGwJ1E20YkyZdRLHxmUJgTyO9vrnaHfHG1XgMbqAv0XQfg2h6m5YDcM9LVY4

