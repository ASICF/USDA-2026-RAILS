import React, { useState, Fragment, useEffect } from "react";

import {
  Button,
  Segment,
  Label,
  Icon,
  Message,
  Header,
  Divider,
  Accordion,
  Breadcrumb,
  Table,
  Form,
  Checkbox,
  Popup,
  Modal,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";
import { tableSortReducer } from "../Shared/TableSort";
import { _ } from "lodash";

export default function FinalDeliverySplit({ packing_slips, token }) {
  const [message, setMessage] = useState(null);
  const [validatedObj, setValidatedObj] = useState(null);
  const [result, setResult] = useState(null);
  const [submitted, setSubmitted] = useState(false);

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const onValidationSubmit = (data) => {
    console.error("onValidationSubmit", data);

    setSubmitted(true);

    axios
      .post(`/final_delivery/splits/execute`, {
        authenticity_token: token,
        packing_slip: data.packing_slip,
        input_directory: data.input_directory,
      })
      .then(({ data }) => {
        console.log(data);

        // Set message
        setMessage({
          status: data.status ? "Success" : "Error",
          text: data.message,
        });

        setSubmitted(false);
      });
  };

  console.log("FinalDelivery Splits", {
    packing_slips,
  });

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Exports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Final Delivery</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Process Splits</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />

      {message && (
        <MessageBox
          status={message.status}
          title={message.title}
          message={message.text}
        />
      )}

      <Form>
        <MessageBox
          status="Notice"
          title="Important"
          message={
            <span>
              This process expects the path to a Tile Dump Folder and it's
              associated Packing Slip. All files are assumed under{" "}
              <b>P:\Vol_1</b>.
            </span>
          }
        />
        <Divider />

        <Form.Group widths="equal">
          <Controller
            name={"input_directory"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, onBlur, onChange, value } }) => (
              <Form.Input
                fluid
                label="Tile Dump Directory"
                autoComplete="off"
                name={name}
                required={true}
                onBlur={onBlur}
                onChange={onChange}
                value={value || ""}
                error={
                  errors["input_directory"] && errors["input_directory"].message
                }
              />
            )}
          />

          <Controller
            name={"packing_slip"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                data-value={value}
                label={"Packing Slip"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={packing_slips.map((record) => {
                  return {
                    key: record.id,
                    value: record.id,
                    text: record.name,
                  };
                })}
                error={
                  errors[name]
                    ? {
                        content: errors[name].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
        </Form.Group>

        <Divider />

        <Button
          primary
          floated="right"
          type="button"
          loading={submitted}
          disabled={submitted}
          onClick={handleSubmit(onValidationSubmit)}
        >
          Submit
        </Button>
        <Button secondary floated="right" type="button" onClick={() => reset()}>
          Reset
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    </div>
  );
}
