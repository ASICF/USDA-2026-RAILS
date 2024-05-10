import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Grid,
  Icon,
  Label,
  Accordion,
  Divider,
  Form,
  Breadcrumb,
  Table,
  Tab,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import RenderValue from "../Shared/RenderValue";
import moment from "moment";
import axios from "axios";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";

const InvoiceNestid = ({ invoices, projects, token }) => {
  const [results, setResults] = useState(false);
  const [message, setMessage] = useState(null);
  const [project, setProject] = useState(null);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    getValues,
    control,
    formState: { errors },
  } = useForm();

  console.log("InvoiceNestid", { invoices, projects, token });

  const resetForm = () => {
    reset({
      project: "",
      invoices: "",
    });
  };

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);

    setSubmitted(true);
    setResults(null);
    setLoading(true);

    axios
      .post(`/invoice_nestid/query`, {
        authenticity_token: token,
        project: data.project,
        invoice_id: data.invoice_id,
      })
      .then((response) => {
        console.log("submit response", response.data);

        setLoading(false);
        setSubmitted(false);
        if (response.data.state) {
          setProject(data.project);
          setResults(response.data.result);
        } else {
          setMessage({
            status: "Error",
            text: response.data.message,
          });
        }

        window.onbeforeunload = null;
      })
      .catch((err) => {
        console.log(err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        setLoading(false);
        setSubmitted(false);
        window.onbeforeunload = null;
      });
  };

  const onExport = (data) => {
    window.open(
      `/invoice_nestid/export?${new URLSearchParams({
        invoice_id: data.invoice_id,
      }).toString()}`,
      "_blank"
    );
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Invoice NestID</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderMessage()}
      {renderLoading()}
      {renderForm()}
      <Divider />
      {renderTable()}
      {/* 
      {renderActiveCounts()}
       */}
      <br />
      <br />
    </div>
  );

  function renderTable() {
    if (!results) return null;

    console.log("renderTable", results);

    if (Object.keys(results).length === 0) {
      return (
        <MessageBox
          title={"No Records Found"}
          message={"Query returned no records"}
        />
      );
    }

    return (
      <Fragment>
        <Divider />
        <Table celled textAlign="center">
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell>State</Table.HeaderCell>
              <Table.HeaderCell>County</Table.HeaderCell>
              <Table.HeaderCell>FIPS</Table.HeaderCell>
              <Table.HeaderCell>Total Easements</Table.HeaderCell>
              <Table.HeaderCell>Total Delivered Easements</Table.HeaderCell>
              <Table.HeaderCell>Date Delivered</Table.HeaderCell>
              <Table.HeaderCell>NestID</Table.HeaderCell>
            </Table.Row>
          </Table.Header>
          <Table.Body>
            {results.map((record, index) => {
              return (
                <Table.Row key={index}>
                  <Table.Cell>{record.state}</Table.Cell>
                  <Table.Cell>{record.county}</Table.Cell>
                  <Table.Cell>{record.full_fips}</Table.Cell>
                  <Table.Cell>{record.count}</Table.Cell>
                  <Table.Cell>{record.shipped_count}</Table.Cell>
                  <Table.Cell>{record.ship_date}</Table.Cell>
                  <Table.Cell>{record.poly_id}</Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>
      </Fragment>
    );
  }

  function renderForm() {
    if (message && message.status === "loading") return null;

    return (
      <Form>
        <Form.Group widths="equal">
          {/* <Controller
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={projects[0]}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                label={"Project"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={projects.map((record) => {
                  return {
                    key: record,
                    text: record,
                    value: record,
                  };
                })}
                error={
                  errors["project"]
                    ? {
                        content: errors["project"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          /> */}
          <Controller
            name={"invoice_id"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue=""
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                label={"Invoices"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={invoices.map((record) => {
                  return {
                    key: record.id,
                    text: `${record.number} (${record.project})`,
                    value: record.id,
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

        <Button.Group floated="right">
          <Button
            primary
            loading={submitted}
            disabled={submitted}
            onClick={handleSubmit(onSubmit)}
          >
            Submit
          </Button>
          <Button.Or />
          <Button onClick={handleSubmit(onExport)}>Export</Button>
        </Button.Group>
        <Button
          secondary
          floated="right"
          type="button"
          style={{ marginRight: "0.5em" }}
          onClick={() => resetForm()}
        >
          Reset
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }

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

  function renderLoading() {
    if (!loading) return null;
    return (
      <MessageBox
        status={"Loading"}
        title={"Loading"}
        message={"Building Table..."}
      />
    );
  }
};

export default InvoiceNestid;
