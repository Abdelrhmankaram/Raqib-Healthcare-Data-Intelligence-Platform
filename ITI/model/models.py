# model/models.py
# Dataclasses matching every table in the DB schema.
# Used by producers, consumers and Spark jobs.

from dataclasses import dataclass, field
from typing import Optional
import json
from datetime import datetime, timezone


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


# ─── Patient ──────────────────────────────────────────────────────────────────

@dataclass
class Patient:
    patient_id:          int
    ssn:                 str
    first_name:          str
    last_name:           str
    birth_date:          str        # ISO date string
    death_date:          Optional[str]
    blood_type:          str
    martial_state:       str
    race:                Optional[str]
    ethnicity:           Optional[str]
    gender:              str
    language:            str
    birth_place:         str
    address:             str
    city:                str
    country:             str
    healthcare_expenses: float
    healthcare_coverage: float
    income:              float
    created_at:          str = field(default_factory=now_iso)

    def to_json(self) -> str:
        return json.dumps(self.__dict__)

    @staticmethod
    def from_json(data: str) -> "Patient":
        return Patient(**json.loads(data))


# ─── Admission ────────────────────────────────────────────────────────────────

@dataclass
class Admission:
    admission_id:          str
    patient_id:            int
    admission_provider_id: str
    admission_datetime_in: str
    admission_datetime_out: Optional[str]
    admission_type:        str        # EMERGENCY | URGENT | ELECTIVE
    admission_location:    str
    discharge_location:    Optional[str]
    insurance_type:        str
    total_cost:            float
    payer_coverage:        float
    hospital_expire_flag:  bool
    primary_sdk:           str
    created_at:            str = field(default_factory=now_iso)

    def to_json(self) -> str:
        return json.dumps(self.__dict__)

    @staticmethod
    def from_json(data: str) -> "Admission":
        return Admission(**json.loads(data))


# ─── Diagnosis ────────────────────────────────────────────────────────────────

@dataclass
class Diagnosis:
    diagnosis_id:    str
    patient_id:      int
    admission_id:    str
    provider_id:     str
    description:     str
    sub_domain_key:  str
    speciality:      str
    sub_domain:      str
    created_at:      str = field(default_factory=now_iso)

    def to_json(self) -> str:
        return json.dumps(self.__dict__)

    @staticmethod
    def from_json(data: str) -> "Diagnosis":
        return Diagnosis(**json.loads(data))


# ─── Prescription ─────────────────────────────────────────────────────────────

@dataclass
class Prescription:
    prescription_id:  str
    patient_id:       int
    admission_id:     str
    provider_id:      str
    drug_id:          str
    prescribed_date:  str       # ISO timestamp
    status:           str       # ACTIVE | COMPLETED | CANCELLED
    created_at:       str = field(default_factory=now_iso)

    def to_json(self) -> str:
        return json.dumps(self.__dict__)

    @staticmethod
    def from_json(data: str) -> "Prescription":
        return Prescription(**json.loads(data))


# ─── Service (transfer path) ──────────────────────────────────────────────────

@dataclass
class Service:
    service_id:       str
    patient_id:       int
    admission_id:     str
    service_name:     str
    service_category: str
    cost:             float
    duration:         int       # minutes
    created_at:       str = field(default_factory=now_iso)

    def to_json(self) -> str:
        return json.dumps(self.__dict__)

    @staticmethod
    def from_json(data: str) -> "Service":
        return Service(**json.loads(data))


# ─── Transfer event (carries everything to 2nd doctor) ───────────────────────

@dataclass
class TransferEvent:
    transfer_id:      str
    patient:          dict       # full Patient as dict
    admission:        dict       # partial Admission as dict
    service:          dict       # Service as dict
    from_provider_id: str
    to_provider_id:   str        # the receiving doctor's static provider id
    from_department:  str
    to_department:    str
    from_room:        str
    to_room:          str
    transfer_datetime: str
    transfer_reason:  str
    doctor_notes:     str        # the original doctor's notes
    created_at:       str = field(default_factory=now_iso)

    def to_json(self) -> str:
        return json.dumps(self.__dict__)

    @staticmethod
    def from_json(data: str) -> "TransferEvent":
        d = json.loads(data)
        return TransferEvent(**d)


# ─── Lab Event ────────────────────────────────────────────────────────────────

@dataclass
class LabEvent:
    lab_event_id:     str
    patient_id:       int
    admission_id:     str
    specimen_id:      str
    item_id:          str
    provider_id:      str
    done_datetime:    str
    stored_datetime:  str
    value:            str
    measurement_unit: str
    range_lower:      float
    range_higher:     float
    abnormal_flag:    bool
    created_at:       str = field(default_factory=now_iso)

    def to_json(self) -> str:
        return json.dumps(self.__dict__)

    @staticmethod
    def from_json(data: str) -> "LabEvent":
        return LabEvent(**json.loads(data))


# ─── Admission message (Path A — full payload) ────────────────────────────────
# Single message that carries admission + diagnosis + prescriptions together
# so Spark can write all three tables in one foreachBatch call.

@dataclass
class AdmissionMessage:
    admission:     dict
    diagnosis:     dict
    prescriptions: list     # list of Prescription dicts

    def to_json(self) -> str:
        return json.dumps(self.__dict__)

    @staticmethod
    def from_json(data: str) -> "AdmissionMessage":
        d = json.loads(data)
        return AdmissionMessage(**d)
