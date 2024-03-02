import React, { useState, Fragment, useEffect } from "react";

import {
  Button,
  Header,
  Modal,
  Icon,
  Divider,
  Segment,
  Breadcrumb,
  Grid,
  Form,
  ButtonContent
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";

export default function Plane({ record, total_flown, companies, token }) {
  const [message, setMessage] = useState(null);
  const [promptDestroy, setPromptDestroy] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  console.error("Planes", { record, total_flown, companies, token, errors });

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const checkboxChange = (e, { name, checked }) => {
    setValue(name, checked);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true);
    setLoading(true)
    var obj = { authenticity_token: token };
    for (const property in data) {
      obj[`plane[${property}]`] = data[property];
    }

    if (record.id) {
      axios
        .patch(`/planes/${record.id}`, {
          plane: data,
          authenticity_token: token,
        })
        .then(({ data }) => handleResponse(data));
    } else {
      axios
        .post(`/planes`, {
          plane: data,
          authenticity_token: token,
        })
        .then(({ data }) => handleResponse(data));
        setLoading(false)
        setSubmitted(false);
    }
  };

  const handleResponse = (data) => {
    console.log("response", data);

    if (data.pass) {
      setMessage({
        status: "Success",
        text: data.message,
      });
      setTimeout(() => {
        window.location.href = "/planes";
      }, 3000);
    } else {
      setMessage({
        status: "Error",
        text: data.message ? data.message : "Something went wrong",
      });
    }
  };

  const destroy = () => {
    console.error("destroy");

    if (canDestroy()) {
      axios
        .delete(`/planes/${record.id}`, {
          data: { authenticity_token: token },
        })
        .then(({ data }) => {
          setPromptDestroy(false);
          handleResponse(data);
        });
    }
  };

  const newRecord = () => {
    return !record.id;
  };

  const canDestroy = () => {
    // console.log("canDestroy", {
    //   total_flown,
    //   id: record.id,
    //   calc: total_flown == 0 && record.id,
    // });
    return total_flown == 0 && record.id;
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Manage</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Planes</Breadcrumb.Section>
        {record.id ? (
          <Fragment>
            <Breadcrumb.Divider />
            <Breadcrumb.Section>{record.id}</Breadcrumb.Section>
            <Breadcrumb.Divider />
            <Breadcrumb.Section active>Edit</Breadcrumb.Section>
          </Fragment>
        ) : (
          <Fragment>
            <Breadcrumb.Divider />
            <Breadcrumb.Section active>New</Breadcrumb.Section>
          </Fragment>
        )}
      </Breadcrumbs>
      <Divider />
      {!newRecord() && (
        <MessageBox
          title={"Notice"}
          message={`If a plane has an associated Footprint it cannot be deleted. Selected Plane has ${total_flown} Footprints.`}
        />
      )}
      {renderMessage()}
      {renderDestroyPrompt()}
      {renderForm()}
    </div>
  );

  function renderMessage() {
    if (!message) return null;

    return (
      <MessageBox
        status={message.status}
        title={message.title}
        message={message.text}
      />
    );
  }

  function renderDestroyPrompt() {
    if (!promptDestroy) return null;

    return (
      <Modal
        basic
        // onClose={() => setOpen(false)}
        // onOpen={() => setOpen(true)}
        open={true}
        size="small"
      >
        <Header icon>
          <Icon name="delete" />
          Are you sure you want to Delete Record?
        </Header>
        <Modal.Content style={{ textAlign: "center" }}>
          <p>
            Proceeding will destroy the record and there is no restoring the
            record.
          </p>
        </Modal.Content>
        <Modal.Actions>
          <Button inverted onClick={() => setPromptDestroy(false)}>
            Cancel
          </Button>
          <Button animated color="red" inverted onClick={() => destroy()}>
          <ButtonContent visible>Destroy</ButtonContent>
            <ButtonContent hidden>
              <Icon name="check circle" />
            </ButtonContent>
          </Button>
        </Modal.Actions>
      </Modal>
    );
  }

  function renderForm() {
    if (message && message.status === "loading") return null;

    return (
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"company_id"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={record.company_id || ""}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                required={true}
                label={"Company"}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={companies.map((record) => {
                  return {
                    key: record.id,
                    text: `${record.name} | ${record.alias}`,
                    value: record.id,
                  };
                })}
                error={
                  errors["company_id"]
                    ? {
                        content: errors["company_id"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
        </Form.Group>

        <Form.Group widths="equal">
          <Controller
            name={"name"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={record.name || ""}
            render={({ field: { name, onBlur, onChange, value } }) => (
              <Form.Input
                fluid
                label={"Name"}
                name={name}
                required={true}
                onBlur={onBlur}
                onChange={onChange}
                value={value || ""}
                error={errors["name"] && errors["name"].message}
              />
            )}
          />
          <Controller
            name={"model"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={record.model || ""}
            render={({ field: { name, onBlur, onChange, value } }) => (
              <Form.Input
                fluid
                label={"Model"}
                name={name}
                required={true}
                onBlur={onBlur}
                onChange={onChange}
                value={value || ""}
                error={errors["model"] && errors["model"].message}
              />
            )}
          />
        </Form.Group>
        <Form.Group inline>
          <label>Included on Projects</label>

          <Controller
            name={"sl"}
            control={control}
            defaultValue={record.sl || false}
            render={({ field: { name, value } }) => (
              <Form.Checkbox
                name={name}
                onClick={checkboxChange}
                checked={value || false}
                label="SL"
              />
            )}
          />
          <Controller
            name={"naip"}
            control={control}
            defaultValue={record.naip || false}
            render={({ field: { name, value } }) => (
              <Form.Checkbox
                name={name}
                onClick={checkboxChange}
                checked={value || false}
                label="NAIP"
              />
            )}
          />
        </Form.Group>

        <Divider />

        {canDestroy() && (
          <Button
            animated="fade"
            color="red"
            floated="left"
            type="button"
            onClick={() => setPromptDestroy(true)}
          >
             <ButtonContent visible>Destroy</ButtonContent>
            <ButtonContent hidden>
              <Icon name="delete" />
            </ButtonContent>
          </Button>
        )}
        <Button
          primary
          animated
          floated="right"
          type="button"
          loading={submitted}
          disabled={submitted}
          onClick={handleSubmit(onSubmit)}
        >
          <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
          <Icon name='arrow right' />
          </ButtonContent>
        </Button>
        <Button animated secondary floated="right" type="button" onClick={() => reset()}>
        <ButtonContent visible>Reset</ButtonContent>
          <ButtonContent hidden>
          <Icon name="undo" />
          </ButtonContent>
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }
}
